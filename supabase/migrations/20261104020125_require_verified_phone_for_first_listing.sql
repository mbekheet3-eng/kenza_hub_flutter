
create or replace function private.is_current_user_phone_verified()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users u
    where u.id = (select auth.uid())
      and u.phone is not null
      and u.phone_confirmed_at is not null
  );
$$;

revoke all on function private.is_current_user_phone_verified() from public, anon;
grant execute on function private.is_current_user_phone_verified() to authenticated;

drop policy if exists products_insert_permission on public.products;
create policy products_insert_permission
on public.products
for insert
to authenticated
with check (
  private.has_seller_permission(seller_id, 'products:create'::text)
  and private.is_current_user_phone_verified()
);

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
set search_path = ''
as $function$
declare
  v_currency uuid;
  v_status uuid;
  v_id uuid;
begin
  if auth.uid() is null or not private.is_active_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not private.is_current_user_phone_verified() then
    raise exception 'PHONE_VERIFICATION_REQUIRED';
  end if;

  if not private.has_seller_permission(p_seller_profile_id,'products:create') then
    raise exception 'PRODUCT_CREATE_PERMISSION_REQUIRED';
  end if;

  if not private.is_seller_in_service_area(p_seller_profile_id) then
    raise exception 'OUTSIDE_DELIVERY_COVERAGE';
  end if;

  if not exists(select 1 from public.categories where id=p_category_id and is_active) then
    raise exception 'INVALID_CATEGORY';
  end if;

  if p_price is null or p_price<=0 then
    raise exception 'INVALID_PRICE';
  end if;

  if p_weight_kg is not null and (p_weight_kg<0 or p_weight_kg>10) then
    raise exception 'WEIGHT_LIMIT_EXCEEDED';
  end if;

  if coalesce(p_audience,'public') not in ('public','followers','private') then
    raise exception 'INVALID_AUDIENCE';
  end if;

  select id into v_currency from public.currencies where code='EGP' and is_active;
  select id into v_status from public.product_statuses where slug='pending_review' and is_active;

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

revoke all on function private.create_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) from public, anon;
grant execute on function private.create_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) to authenticated;
