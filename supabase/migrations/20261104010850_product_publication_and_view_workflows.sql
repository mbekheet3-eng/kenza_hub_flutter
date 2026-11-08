
-- Complete order agreement snapshot fields without enabling checkout/order creation.
alter table public.orders
  add column platform_fee numeric(12,2) not null default 0 check(platform_fee>=0),
  add column shipping_cost numeric(12,2) not null default 0 check(shipping_cost>=0),
  add column agreed_unit_price numeric(12,2) check(agreed_unit_price is null or agreed_unit_price>=0),
  add column agreed_shipping_method text,
  add column agreed_shipping_cost numeric(12,2) check(agreed_shipping_cost is null or agreed_shipping_cost>=0),
  add column agreed_fees jsonb,
  add column agreed_delivery_terms jsonb;

create table public.product_view_events (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  viewer_user_id uuid not null references public.users(id) on delete cascade,
  viewed_on date not null default current_date,
  created_at timestamptz not null default now(),
  unique(product_id,viewer_user_id,viewed_on)
);
alter table public.product_view_events enable row level security;
-- Intentionally no direct table grants or policies; views are counted through the RPC only.

create or replace function private.is_seller_in_service_area(p_profile_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(
  select 1 from public.seller_profiles sp
  join public.users u on u.id=sp.owner_user_id
  join public.regions r on r.id=u.default_region_id
  where sp.id=p_profile_id and sp.is_active and u.is_active and r.is_active and r.is_delivery_active
 )
$$;
grant execute on function private.is_seller_in_service_area(uuid) to authenticated;

create or replace function private.create_product(
 p_category_id uuid,p_title_ar text,p_title_en text,p_description_ar text,p_description_en text,
 p_price numeric,p_condition_id uuid,p_color_id uuid,p_size_id uuid,p_brand_name text,
 p_weight_kg numeric,p_audience text
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_profile uuid; v_currency uuid; v_status uuid; v_id uuid;
begin
 if auth.uid() is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 select id into v_profile from public.seller_profiles where owner_user_id=auth.uid() and is_active;
 if v_profile is null then raise exception 'SELLER_PROFILE_REQUIRED'; end if;
 if not private.has_seller_permission(v_profile,'products:create') then raise exception 'PRODUCT_CREATE_PERMISSION_REQUIRED'; end if;
 if not private.is_seller_in_service_area(v_profile) then raise exception 'OUTSIDE_DELIVERY_COVERAGE'; end if;
 if not exists(select 1 from public.categories where id=p_category_id and is_active) then raise exception 'INVALID_CATEGORY'; end if;
 if p_price is null or p_price<=0 then raise exception 'INVALID_PRICE'; end if;
 if p_weight_kg is not null and (p_weight_kg<0 or p_weight_kg>10) then raise exception 'WEIGHT_LIMIT_EXCEEDED'; end if;
 if coalesce(p_audience,'public') not in ('public','followers','private') then raise exception 'INVALID_AUDIENCE'; end if;
 select id into v_currency from public.currencies where code='EGP' and is_active;
 select id into v_status from public.product_statuses where slug='pending_review' and is_active;
 if v_currency is null or v_status is null then raise exception 'REFERENCE_DATA_NOT_READY'; end if;
 insert into public.products(seller_id,category_id,title_ar,title_en,description_ar,description_en,price,currency_id,
  condition_id,color_id,size_id,status_id,brand_name,weight_kg,audience,moderation_status,published_at)
 values(v_profile,p_category_id,trim(p_title_ar),nullif(trim(p_title_en),''),p_description_ar,p_description_en,p_price,
  v_currency,p_condition_id,p_color_id,p_size_id,v_status,nullif(trim(p_brand_name),''),p_weight_kg,
  coalesce(p_audience,'public'),'pending',null)
 returning id into v_id;
 return v_id;
end $$;
revoke all on function private.create_product(uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) from public,anon;
grant execute on function private.create_product(uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) to authenticated;
create function public.create_product(
 p_category_id uuid,p_title_ar text,p_title_en text,p_description_ar text,p_description_en text,
 p_price numeric,p_condition_id uuid,p_color_id uuid default null,p_size_id uuid default null,
 p_brand_name text default null,p_weight_kg numeric default null,p_audience text default 'public'
) returns uuid language sql set search_path=''
as $$ select private.create_product($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) $$;
revoke all on function public.create_product(uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) from public,anon;
grant execute on function public.create_product(uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) to authenticated;

create or replace function private.add_product_image(p_product_id uuid,p_image_path text,p_display_order integer)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 if not private.has_seller_permission((select seller_id from public.products where id=p_product_id),'products:update') then
   raise exception 'PRODUCT_IMAGE_PERMISSION_REQUIRED';
 end if;
 if p_image_path !~ ('^products/'||auth.uid()::text||'/[^/]+$') then raise exception 'INVALID_IMAGE_PATH'; end if;
 if not exists(select 1 from storage.objects where bucket_id='product-images' and name=p_image_path) then raise exception 'IMAGE_OBJECT_NOT_FOUND'; end if;
 insert into public.product_images(product_id,image_path,display_order)
 values(p_product_id,p_image_path,p_display_order) returning id into v_id;
 return v_id;
end $$;
revoke all on function private.add_product_image(uuid,text,integer) from public,anon;
grant execute on function private.add_product_image(uuid,text,integer) to authenticated;
create function public.add_product_image(p_product_id uuid,p_image_path text,p_display_order integer)
returns uuid language sql set search_path=''
as $$ select private.add_product_image($1,$2,$3) $$;
revoke all on function public.add_product_image(uuid,text,integer) from public,anon;
grant execute on function public.add_product_image(uuid,text,integer) to authenticated;

create or replace function private.moderate_product(p_product_id uuid,p_decision text,p_reason text default null)
returns void language plpgsql security definer set search_path=''
as $$
declare v_product public.products%rowtype; v_available uuid; v_hidden uuid;
begin
 if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
 if p_decision not in ('approved','rejected','hidden') then raise exception 'INVALID_DECISION'; end if;
 select * into v_product from public.products where id=p_product_id for update;
 if v_product.id is null then raise exception 'PRODUCT_NOT_FOUND'; end if;
 if p_decision='approved' then
   if not private.is_seller_in_service_area(v_product.seller_id) then raise exception 'SELLER_OUTSIDE_DELIVERY_COVERAGE'; end if;
   select id into v_available from public.product_statuses where slug='available';
   update public.products set moderation_status='approved',status_id=v_available,published_at=now() where id=p_product_id;
 else
   select id into v_hidden from public.product_statuses where slug='hidden';
   update public.products set moderation_status=p_decision,status_id=v_hidden,published_at=null where id=p_product_id;
 end if;
 insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,before_data,after_data)
 values(auth.uid(),'product.moderated','products',p_product_id,p_reason,
  jsonb_build_object('moderation_status',v_product.moderation_status),
  jsonb_build_object('moderation_status',p_decision));
end $$;
revoke all on function private.moderate_product(uuid,text,text) from public,anon;
grant execute on function private.moderate_product(uuid,text,text) to authenticated;
create function public.moderate_product(p_product_id uuid,p_decision text,p_reason text default null)
returns void language sql set search_path=''
as $$ select private.moderate_product($1,$2,$3) $$;
revoke all on function public.moderate_product(uuid,text,text) from public,anon;
grant execute on function public.moderate_product(uuid,text,text) to authenticated;

create or replace function private.increment_product_views(p_product_id uuid)
returns bigint language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_inserted integer;
begin
 if v_uid is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 if not exists(select 1 from public.products where id=p_product_id and moderation_status='approved' and audience in ('public','followers')) then
   raise exception 'PRODUCT_NOT_AVAILABLE';
 end if;
 insert into public.product_view_events(product_id,viewer_user_id,viewed_on)
 values(p_product_id,v_uid,current_date)
 on conflict(product_id,viewer_user_id,viewed_on) do nothing;
 get diagnostics v_inserted = row_count;
 if v_inserted=1 then
   update public.products set views_count=views_count+1 where id=p_product_id;
 end if;
 return (select views_count from public.products where id=p_product_id);
end $$;
revoke all on function private.increment_product_views(uuid) from public,anon;
grant execute on function private.increment_product_views(uuid) to authenticated;
create function public.increment_product_views(p_product_id uuid)
returns bigint language sql set search_path=''
as $$ select private.increment_product_views($1) $$;
revoke all on function public.increment_product_views(uuid) from public,anon;
grant execute on function public.increment_product_views(uuid) to authenticated;

-- No direct client writes to product rows or image metadata; all changes go through checked RPCs.
revoke insert,update,delete on public.products,public.product_images from anon,authenticated;
grant select on public.product_view_events to authenticated;
revoke all on public.product_view_events from anon,authenticated;
