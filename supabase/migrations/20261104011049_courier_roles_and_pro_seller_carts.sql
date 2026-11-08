-- Explicit deny policies document that these tables are RPC/service-only.
create policy product_view_events_no_direct_access on public.product_view_events
for all to anon,authenticated using(false) with check(false);
create policy referrals_owner_read on public.referrals for select to authenticated
using(private.is_active_user() and (referrer_user_id=(select auth.uid()) or referred_user_id=(select auth.uid())));

drop policy if exists reports_admin_read on public.reports;
drop policy if exists reports_owner_read on public.reports;
create policy reports_participant_or_admin_read on public.reports for select to authenticated
using(private.is_active_user() and (reporter_user_id=(select auth.uid()) or private.is_admin()));

drop index if exists public.product_view_events_viewer_fk_idx;
create index if not exists offers_product_fk_idx on public.offers(product_id);
create index if not exists products_brand_fk_idx on public.products(brand_id);
create index if not exists reports_reporter_fk_idx on public.reports(reporter_user_id);
create index if not exists reports_reviewer_fk_idx on public.reports(reviewed_by);

drop policy if exists product_images_read on public.product_images;
create policy product_images_read on public.product_images for select to anon,authenticated using (
 exists(select 1 from public.products p where p.id=product_id and (
   (p.moderation_status='approved' and p.audience='public')
   or ((select auth.uid()) is not null and p.moderation_status='approved' and p.audience='followers'
       and exists(select 1 from public.follows f where f.follower_user_id=(select auth.uid()) and f.followed_seller_profile_id=p.seller_id))
   or ((select auth.uid()) is not null and private.has_seller_permission(p.seller_id,'products:read'))
 ))
);

create or replace function private.get_or_create_chat(p_product_id uuid)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_seller uuid; v_chat uuid; v_owner uuid;
begin
 if v_uid is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 select seller_id into v_seller from public.products p
 where p.id=p_product_id and p.moderation_status='approved'
 and (p.audience='public' or (p.audience='followers' and exists(
   select 1 from public.follows f where f.follower_user_id=v_uid and f.followed_seller_profile_id=p.seller_id
 )));
 if v_seller is null then raise exception 'PRODUCT_NOT_AVAILABLE'; end if;
 select owner_user_id into v_owner from public.seller_profiles where id=v_seller;
 if v_owner=v_uid then raise exception 'SELF_CHAT_NOT_ALLOWED'; end if;
 if exists(select 1 from public.user_blocks where (blocker_user_id=v_uid and blocked_user_id=v_owner)
    or (blocked_user_id=v_uid and blocker_user_id=v_owner)) then raise exception 'CHAT_BLOCKED'; end if;
 insert into public.chats(product_id,buyer_id,seller_profile_id)
 values(p_product_id,v_uid,v_seller)
 on conflict(product_id,buyer_id) do update set product_id=excluded.product_id
 returning id into v_chat;
 return v_chat;
end $$;

create or replace function private.create_offer(p_product_id uuid,p_offered_price numeric,p_expires_at timestamptz default null)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_id uuid; v_audience text;
begin
 if not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 select seller_id,audience into v_seller,v_audience from public.products
 where id=p_product_id and moderation_status='approved';
 if v_seller is null or not (v_audience='public' or (v_audience='followers' and exists(
   select 1 from public.follows f where f.follower_user_id=auth.uid() and f.followed_seller_profile_id=v_seller
 ))) then raise exception 'PRODUCT_NOT_AVAILABLE'; end if;
 if private.has_seller_permission(v_seller,'products:read') then raise exception 'SELF_OFFER_NOT_ALLOWED'; end if;
 if p_offered_price<=0 or p_offered_price >= (select price from public.products where id=p_product_id) then raise exception 'INVALID_OFFER_PRICE'; end if;
 insert into public.offers(product_id,seller_profile_id,buyer_user_id,offered_price,expires_at)
 values(p_product_id,v_seller,auth.uid(),p_offered_price,p_expires_at) returning id into v_id;
 return v_id;
end $$;

create table public.courier_profiles (
 user_id uuid primary key references public.users(id) on delete restrict,
 is_active boolean not null default true,
 created_by uuid references public.users(id) on delete set null,
 created_at timestamptz not null default now(),
 deactivated_at timestamptz
);
alter table public.courier_profiles enable row level security;
create policy courier_profiles_admin_read on public.courier_profiles for select to authenticated using(private.is_admin());
grant select on public.courier_profiles to authenticated;

create or replace function private.assign_delivery_courier(p_order_id uuid,p_courier_user_id uuid,p_reason text)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_assignment uuid;
begin
 select seller_profile_id into v_seller from public.orders where id=p_order_id;
 if v_seller is null then raise exception 'ORDER_NOT_FOUND'; end if;
 if not private.is_admin() and not private.is_seller_owner(v_seller) then raise exception 'NOT_AUTHORIZED'; end if;
 if not exists(select 1 from public.courier_profiles c join public.users u on u.id=c.user_id
   where c.user_id=p_courier_user_id and c.is_active and u.is_active) then raise exception 'COURIER_NOT_ACTIVE'; end if;
 update public.delivery_assignments set status='revoked',ended_at=now()
 where order_id=p_order_id and ended_at is null;
 insert into public.delivery_assignments(order_id,courier_user_id,assigned_by)
 values(p_order_id,p_courier_user_id,auth.uid()) returning id into v_assignment;
 insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,after_data)
 values(auth.uid(),'delivery.courier_assigned','delivery_assignments',v_assignment,p_reason,
   jsonb_build_object('order_id',p_order_id,'courier_user_id',p_courier_user_id));
 return v_assignment;
end $$;

create or replace function private.manage_courier(p_user_id uuid,p_activate boolean,p_reason text)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
 if not exists(select 1 from public.users where id=p_user_id and is_active) then raise exception 'USER_NOT_ACTIVE'; end if;
 if p_activate then
   insert into public.courier_profiles(user_id,is_active,created_by) values(p_user_id,true,auth.uid())
   on conflict(user_id) do update set is_active=true,deactivated_at=null;
 else
   update public.courier_profiles set is_active=false,deactivated_at=now() where user_id=p_user_id;
   update public.delivery_assignments set status='revoked',ended_at=now()
   where courier_user_id=p_user_id and ended_at is null;
 end if;
 insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,after_data)
 values(auth.uid(),case when p_activate then 'courier.activated' else 'courier.deactivated' end,
  'courier_profiles',p_user_id,p_reason,jsonb_build_object('is_active',p_activate));
end $$;
revoke all on function private.manage_courier(uuid,boolean,text) from public,anon;
grant execute on function private.manage_courier(uuid,boolean,text) to authenticated;
create function public.manage_courier(p_user_id uuid,p_activate boolean,p_reason text)
returns void language sql set search_path=''
as $$ select private.manage_courier($1,$2,$3) $$;
revoke all on function public.manage_courier(uuid,boolean,text) from public,anon;
grant execute on function public.manage_courier(uuid,boolean,text) to authenticated;

create table public.carts (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.users(id) on delete cascade,
 seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 unique(user_id,seller_profile_id)
);
create table public.cart_items (
 id uuid primary key default gen_random_uuid(),
 cart_id uuid not null references public.carts(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete restrict,
 quantity integer not null default 1 check(quantity=1),
 unit_price_at_add numeric(12,2) not null check(unit_price_at_add>0),
 created_at timestamptz not null default now(),
 unique(cart_id,product_id)
);
create index cart_items_product_idx on public.cart_items(product_id);
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
create policy carts_owner_read on public.carts for select to authenticated
using(private.is_active_user() and user_id=(select auth.uid()));
create policy cart_items_owner_read on public.cart_items for select to authenticated
using(exists(select 1 from public.carts c where c.id=cart_id and c.user_id=(select auth.uid()) and private.is_active_user()));
grant select on public.carts,public.cart_items to authenticated;

create or replace function private.add_to_cart(p_product_id uuid)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_seller uuid; v_price numeric; v_cart uuid; v_item uuid;
begin
 if v_uid is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 select p.seller_id,p.price into v_seller,v_price
 from public.products p join public.seller_profiles sp on sp.id=p.seller_id
 where p.id=p_product_id and p.moderation_status='approved' and p.audience='public'
   and sp.seller_type='pro_seller' and sp.is_active;
 if v_seller is null then raise exception 'CART_AVAILABLE_FOR_PRO_SELLERS_ONLY'; end if;
 if private.has_seller_permission(v_seller,'products:read') then raise exception 'SELF_PURCHASE_NOT_ALLOWED'; end if;
 insert into public.carts(user_id,seller_profile_id) values(v_uid,v_seller)
 on conflict(user_id,seller_profile_id) do update set updated_at=now()
 returning id into v_cart;
 insert into public.cart_items(cart_id,product_id,quantity,unit_price_at_add)
 values(v_cart,p_product_id,1,v_price)
 on conflict(cart_id,product_id) do update set unit_price_at_add=excluded.unit_price_at_add
 returning id into v_item;
 return v_cart;
end $$;
revoke all on function private.add_to_cart(uuid) from public,anon;
grant execute on function private.add_to_cart(uuid) to authenticated;
create function public.add_to_cart(p_product_id uuid)
returns uuid language sql set search_path=''
as $$ select private.add_to_cart($1) $$;
revoke all on function public.add_to_cart(uuid) from public,anon;
grant execute on function public.add_to_cart(uuid) to authenticated;

create or replace function private.remove_from_cart(p_cart_item_id uuid)
returns void language plpgsql security definer set search_path=''
as $$
begin
 if not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 delete from public.cart_items i using public.carts c
 where i.id=p_cart_item_id and c.id=i.cart_id and c.user_id=auth.uid();
end $$;
revoke all on function private.remove_from_cart(uuid) from public,anon;
grant execute on function private.remove_from_cart(uuid) to authenticated;
create function public.remove_from_cart(p_cart_item_id uuid)
returns void language sql set search_path=''
as $$ select private.remove_from_cart($1) $$;
revoke all on function public.remove_from_cart(uuid) from public,anon;
grant execute on function public.remove_from_cart(uuid) to authenticated;

create trigger carts_touch_updated before update on public.carts
for each row execute function private.touch_updated_at();

