-- Product decision (2026-11-08):
-- 1) Phone verification is suspended until further notice.
-- 2) Listings and buyer/seller-arranged delivery are permitted throughout Egypt.
-- Kenza delivery centers/radii are optional logistics conveniences, not listing gates.

-- Keep direct INSERT policy aligned with the current product rule while retaining
-- seller permission enforcement. The controlled RPC remains the intended write path.
drop policy if exists products_insert_permission on public.products;
create policy products_insert_permission
on public.products
for insert
to authenticated
with check (
  private.has_seller_permission(seller_id, 'products:create'::text)
);

-- Seller profile creation no longer requires phone confirmation.
create or replace function private.create_seller_profile(
  p_display_name text,
  p_bio text default null
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_profile_id uuid;
begin
  if v_user_id is null or not private.is_active_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  if p_display_name is null or char_length(trim(p_display_name)) not between 3 and 60 then
    raise exception 'INVALID_DISPLAY_NAME';
  end if;

  if exists (
    select 1 from public.seller_profiles where owner_user_id=v_user_id
  ) or exists (
    select 1 from public.seller_profile_members
    where user_id=v_user_id and revoked_at is null
  ) then
    raise exception 'SELLER_PROFILE_ALREADY_EXISTS';
  end if;

  insert into public.seller_profiles(
    owner_user_id,display_name,bio,seller_type,business_type
  )
  values(
    v_user_id,trim(p_display_name),nullif(trim(p_bio),''),'seller','individual'
  )
  returning id into v_profile_id;

  insert into public.seller_profile_members(
    seller_profile_id,user_id,member_role,permissions
  )
  values(
    v_profile_id,v_user_id,'owner',
    '{"products:read":true,"products:create":true,"products:update":true,"products:delete":true,"exchange:manage":false}'::jsonb
  );

  return v_profile_id;
end
$function$;

revoke all on function private.create_seller_profile(text,text) from public,anon;
grant execute on function private.create_seller_profile(text,text) to authenticated;

-- Product creation remains guarded by active-account, seller permission,
-- catalog, price, weight and audience validation; phone and delivery radius
-- are intentionally not requirements.
create or replace function private.create_product(
  p_seller_profile_id uuid,
  p_category_id uuid,
  p_title_ar text,
  p_title_en text,
  p_description_ar text,
  p_description_en text,
  p_price numeric,
  p_condition_id uuid,
  p_color_id uuid,
  p_size_id uuid,
  p_brand_name text,
  p_weight_kg numeric,
  p_audience text
)
returns uuid
language plpgsql
security definer
set search_path=''
as $function$
declare
  v_currency uuid;
  v_status uuid;
  v_id uuid;
begin
  if auth.uid() is null or not private.is_active_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not private.has_seller_permission(p_seller_profile_id,'products:create') then
    raise exception 'PRODUCT_CREATE_PERMISSION_REQUIRED';
  end if;

  if p_title_ar is null or char_length(trim(p_title_ar)) not between 3 and 140 then
    raise exception 'INVALID_PRODUCT_TITLE';
  end if;

  if not exists (
    select 1 from public.categories where id=p_category_id and is_active
  ) then
    raise exception 'INVALID_CATEGORY';
  end if;

  if not exists (
    select 1 from public.product_conditions where id=p_condition_id and is_active
  ) then
    raise exception 'INVALID_PRODUCT_CONDITION';
  end if;

  if p_color_id is not null and not exists (
    select 1 from public.product_colors where id=p_color_id and is_active
  ) then
    raise exception 'INVALID_PRODUCT_COLOR';
  end if;

  if p_size_id is not null and not exists (
    select 1 from public.product_sizes where id=p_size_id and is_active
  ) then
    raise exception 'INVALID_PRODUCT_SIZE';
  end if;

  if p_price is null or p_price <= 0 then
    raise exception 'INVALID_PRICE';
  end if;

  if p_weight_kg is not null and (p_weight_kg <= 0 or p_weight_kg > 10) then
    raise exception 'WEIGHT_LIMIT_EXCEEDED';
  end if;

  if coalesce(p_audience,'public') not in ('public','followers','private') then
    raise exception 'INVALID_AUDIENCE';
  end if;

  select id into v_currency
  from public.currencies where code='EGP' and is_active;

  select id into v_status
  from public.product_statuses where slug='pending_review' and is_active;

  if v_currency is null or v_status is null then
    raise exception 'REFERENCE_DATA_NOT_READY';
  end if;

  insert into public.products(
    seller_id,category_id,title_ar,title_en,description_ar,description_en,
    price,currency_id,condition_id,color_id,size_id,status_id,brand_name,
    weight_kg,audience,moderation_status,published_at
  )
  values(
    p_seller_profile_id,p_category_id,trim(p_title_ar),nullif(trim(p_title_en),''),
    p_description_ar,p_description_en,p_price,v_currency,p_condition_id,p_color_id,
    p_size_id,v_status,nullif(trim(p_brand_name),''),p_weight_kg,
    coalesce(p_audience,'public'),'pending',null
  )
  returning id into v_id;

  return v_id;
end
$function$;

revoke all on function private.create_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) from public,anon;
grant execute on function private.create_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) to authenticated;
