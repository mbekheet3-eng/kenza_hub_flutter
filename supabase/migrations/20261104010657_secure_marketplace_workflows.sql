create table public.user_blocks (
  blocker_user_id uuid not null references public.users(id) on delete cascade,
  blocked_user_id uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(blocker_user_id,blocked_user_id),
  check(blocker_user_id <> blocked_user_id)
);
alter table public.user_blocks enable row level security;
create policy user_blocks_owner_all on public.user_blocks for all to authenticated
using (blocker_user_id=(select auth.uid())) with check (blocker_user_id=(select auth.uid()));
grant select,insert,delete on public.user_blocks to authenticated;

create or replace function private.is_active_user()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.users u where u.id=(select auth.uid()) and u.is_active) $$;
grant execute on function private.is_active_user() to authenticated;

create or replace function private.is_dispute_participant(p_dispute_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists(
    select 1 from public.disputes d join public.orders o on o.id=d.order_id
    where d.id=p_dispute_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id))
  )
$$;
grant execute on function private.is_dispute_participant(uuid) to authenticated;

create or replace function public.create_seller_profile(
  p_display_name text,
  p_bio text default null
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_user_id uuid := auth.uid(); v_profile_id uuid;
begin
  if v_user_id is null or not private.is_active_user() then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_display_name is null or char_length(trim(p_display_name)) not between 3 and 60 then
    raise exception 'INVALID_DISPLAY_NAME';
  end if;
  if exists(select 1 from public.seller_profiles where owner_user_id=v_user_id)
     or exists(select 1 from public.seller_profile_members where user_id=v_user_id and revoked_at is null) then
    raise exception 'SELLER_PROFILE_ALREADY_EXISTS';
  end if;
  insert into public.seller_profiles(owner_user_id,display_name,bio,seller_type,business_type)
  values(v_user_id,trim(p_display_name),nullif(trim(p_bio),''),'seller','individual')
  returning id into v_profile_id;
  insert into public.seller_profile_members(seller_profile_id,user_id,member_role,permissions)
  values(v_profile_id,v_user_id,'owner',
    '{"products:read":true,"products:create":true,"products:update":true,"products:delete":true,"exchange:manage":false}'::jsonb);
  return v_profile_id;
end $$;
revoke all on function public.create_seller_profile(text,text) from public,anon;
grant execute on function public.create_seller_profile(text,text) to authenticated;

create or replace function public.manage_seller_member(
  p_seller_profile_id uuid,
  p_action text,
  p_member_user_id uuid,
  p_permissions jsonb default '{}'::jsonb
) returns void
language plpgsql security definer set search_path = ''
as $$
declare v_allowed constant text[] := array['products:read','products:create','products:update','products:delete','exchange:manage'];
begin
  if auth.uid() is null or not private.is_active_user() or not private.is_seller_owner(p_seller_profile_id) then
    raise exception 'OWNER_ONLY';
  end if;
  if p_member_user_id=auth.uid() then raise exception 'OWNER_CANNOT_EDIT_SELF_MEMBERSHIP'; end if;
  if p_action='invite_or_update' then
    if jsonb_typeof(coalesce(p_permissions,'{}'::jsonb)) <> 'object'
       or exists(select 1 from jsonb_object_keys(coalesce(p_permissions,'{}'::jsonb)) k where not (k=any(v_allowed)))
       or exists(select 1 from jsonb_each(coalesce(p_permissions,'{}'::jsonb)) e where jsonb_typeof(e.value)<>'boolean') then
      raise exception 'INVALID_PERMISSION_SET';
    end if;
    insert into public.seller_profile_members(seller_profile_id,user_id,member_role,permissions,invited_by,revoked_at)
    values(p_seller_profile_id,p_member_user_id,'employee',coalesce(p_permissions,'{}'::jsonb),auth.uid(),null)
    on conflict(seller_profile_id,user_id) do update
      set permissions=excluded.permissions,revoked_at=null,invited_by=auth.uid(),member_role='employee';
  elsif p_action='revoke' then
    update public.seller_profile_members set revoked_at=now()
    where seller_profile_id=p_seller_profile_id and user_id=p_member_user_id and member_role='employee' and revoked_at is null;
  else
    raise exception 'INVALID_ACTION';
  end if;
end $$;
revoke all on function public.manage_seller_member(uuid,text,uuid,jsonb) from public,anon;
grant execute on function public.manage_seller_member(uuid,text,uuid,jsonb) to authenticated;

create or replace function public.get_or_create_chat(p_product_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_uid uuid:=auth.uid(); v_seller uuid; v_chat uuid;
begin
  if v_uid is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
  select seller_id into v_seller from public.products
  where id=p_product_id and moderation_status='approved' and audience='public';
  if v_seller is null then raise exception 'PRODUCT_NOT_AVAILABLE'; end if;
  if exists(select 1 from public.seller_profiles where id=v_seller and owner_user_id=v_uid) then raise exception 'SELF_CHAT_NOT_ALLOWED'; end if;
  if exists(select 1 from public.user_blocks where (blocker_user_id=v_uid and blocked_user_id=(select owner_user_id from public.seller_profiles where id=v_seller))
      or (blocked_user_id=v_uid and blocker_user_id=(select owner_user_id from public.seller_profiles where id=v_seller))) then
    raise exception 'CHAT_BLOCKED';
  end if;
  insert into public.chats(product_id,buyer_id,seller_profile_id)
  values(p_product_id,v_uid,v_seller)
  on conflict(product_id,buyer_id) do update set product_id=excluded.product_id
  returning id into v_chat;
  return v_chat;
end $$;
revoke all on function public.get_or_create_chat(uuid) from public,anon;
grant execute on function public.get_or_create_chat(uuid) to authenticated;

create or replace function public.assign_delivery_courier(p_order_id uuid,p_courier_user_id uuid,p_reason text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_seller uuid; v_assignment uuid;
begin
  select seller_profile_id into v_seller from public.orders where id=p_order_id;
  if v_seller is null then raise exception 'ORDER_NOT_FOUND'; end if;
  if not private.is_admin() and not private.is_seller_owner(v_seller) then raise exception 'NOT_AUTHORIZED'; end if;
  if not exists(select 1 from public.users where id=p_courier_user_id and is_active) then raise exception 'COURIER_NOT_ACTIVE'; end if;
  update public.delivery_assignments set status='revoked',ended_at=now()
  where order_id=p_order_id and ended_at is null;
  insert into public.delivery_assignments(order_id,courier_user_id,assigned_by)
  values(p_order_id,p_courier_user_id,auth.uid()) returning id into v_assignment;
  insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,after_data)
  values(auth.uid(),'delivery.courier_assigned','delivery_assignments',v_assignment,p_reason,
    jsonb_build_object('order_id',p_order_id,'courier_user_id',p_courier_user_id));
  return v_assignment;
end $$;
revoke all on function public.assign_delivery_courier(uuid,uuid,text) from public,anon;
grant execute on function public.assign_delivery_courier(uuid,uuid,text) to authenticated;

create or replace function public.get_my_delivery_details(p_order_id uuid)
returns table(
  order_id uuid,recipient_name text,recipient_phone text,address_line_1 text,address_line_2 text,
  landmark text,region_id uuid,latitude numeric,longitude numeric,delivery_notes text
)
language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
  return query
  select d.order_id,d.recipient_name,d.recipient_phone,d.address_line_1,d.address_line_2,
    d.landmark,d.region_id,d.latitude,d.longitude,d.delivery_notes
  from public.order_delivery_details d
  join public.delivery_assignments a on a.order_id=d.order_id
  where d.order_id=p_order_id and a.courier_user_id=auth.uid()
    and a.ended_at is null and a.status in ('assigned','accepted','in_transit')
    and (d.retention_expires_at>now() or d.legal_hold);
end $$;
revoke all on function public.get_my_delivery_details(uuid) from public,anon;
grant execute on function public.get_my_delivery_details(uuid) to authenticated;

create or replace function public.admin_transition_dispute(
  p_dispute_id uuid,p_new_status text,p_decision text,p_reason text
) returns void
language plpgsql security definer set search_path = ''
as $$
declare v_old text;
begin
  if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
  if p_new_status not in ('under_review','awaiting_response','resolved','rejected','closed') then raise exception 'INVALID_STATUS'; end if;
  select status into v_old from public.disputes where id=p_dispute_id for update;
  if v_old is null then raise exception 'DISPUTE_NOT_FOUND'; end if;
  if v_old in ('resolved','rejected','closed') then raise exception 'DISPUTE_FINAL'; end if;
  update public.disputes set status=p_new_status,
    admin_decision=case when p_new_status in ('resolved','rejected','closed') then p_decision else admin_decision end,
    resolved_by=case when p_new_status in ('resolved','rejected','closed') then auth.uid() else resolved_by end,
    resolved_at=case when p_new_status in ('resolved','rejected','closed') then now() else resolved_at end
  where id=p_dispute_id;
  insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,before_data,after_data)
  values(auth.uid(),'dispute.status_changed','disputes',p_dispute_id,p_reason,
    jsonb_build_object('status',v_old),jsonb_build_object('status',p_new_status,'decision',p_decision));
end $$;
revoke all on function public.admin_transition_dispute(uuid,text,text,text) from public,anon;
grant execute on function public.admin_transition_dispute(uuid,text,text,text) to authenticated;

create or replace function public.submit_dispute_consent(p_dispute_id uuid,p_proposed_status text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_id uuid;
begin
  if not private.is_active_user() or not private.is_dispute_participant(p_dispute_id) then raise exception 'NOT_A_DISPUTE_PARTICIPANT'; end if;
  if p_proposed_status not in ('awaiting_response','resolved') then raise exception 'INVALID_PROPOSAL'; end if;
  insert into public.dispute_status_consents(dispute_id,user_id,proposed_status)
  values(p_dispute_id,auth.uid(),p_proposed_status)
  on conflict(dispute_id,user_id,proposed_status) do update set consented_at=now()
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.submit_dispute_consent(uuid,text) from public,anon;
grant execute on function public.submit_dispute_consent(uuid,text) to authenticated;
drop policy if exists dispute_consents_insert on public.dispute_status_consents;
revoke insert on public.dispute_status_consents from authenticated;

create or replace function public.place_auction_bid(p_auction_id uuid,p_amount numeric)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_auction public.auctions%rowtype; v_high numeric; v_id uuid;
begin
  if auth.uid() is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
  perform pg_advisory_xact_lock(hashtext(p_auction_id::text));
  select * into v_auction from public.auctions where id=p_auction_id for update;
  if v_auction.id is null or v_auction.status<>'live' or now()<v_auction.starts_at or now()>=v_auction.ends_at then raise exception 'AUCTION_NOT_LIVE'; end if;
  if exists(select 1 from public.seller_profiles where id=v_auction.seller_profile_id and owner_user_id=auth.uid()) then raise exception 'SELLER_CANNOT_BID'; end if;
  select max(amount) into v_high from public.auction_bids where auction_id=p_auction_id;
  if p_amount < coalesce(v_high,v_auction.starting_price-v_auction.minimum_increment)+v_auction.minimum_increment then raise exception 'BID_TOO_LOW'; end if;
  insert into public.auction_bids(auction_id,bidder_user_id,amount) values(p_auction_id,auth.uid(),p_amount) returning id into v_id;
  return v_id;
end $$;
revoke all on function public.place_auction_bid(uuid,numeric) from public,anon;
grant execute on function public.place_auction_bid(uuid,numeric) to authenticated;

create or replace function public.create_exchange_offer(
  p_target_seller_profile_id uuid,p_offered_product_id uuid,p_requested_product_id uuid
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_source uuid; v_id uuid;
begin
  select id into v_source from public.seller_profiles where owner_user_id=auth.uid() and seller_type='pro_seller' and is_active;
  if v_source is null then raise exception 'PRO_SELLER_ONLY'; end if;
  if not exists(select 1 from public.seller_profiles where id=p_target_seller_profile_id and seller_type='pro_seller' and is_active) then raise exception 'TARGET_MUST_BE_PRO_SELLER'; end if;
  if not private.has_seller_permission(v_source,'exchange:manage') then raise exception 'EXCHANGE_PERMISSION_REQUIRED'; end if;
  if not exists(select 1 from public.products where id=p_offered_product_id and seller_id=v_source) then raise exception 'OFFERED_PRODUCT_NOT_OWNED'; end if;
  if not exists(select 1 from public.products where id=p_requested_product_id and seller_id=p_target_seller_profile_id) then raise exception 'REQUESTED_PRODUCT_NOT_OWNED'; end if;
  insert into public.exchange_offers(proposer_seller_profile_id,target_seller_profile_id,offered_product_id,requested_product_id)
  values(v_source,p_target_seller_profile_id,p_offered_product_id,p_requested_product_id) returning id into v_id;
  return v_id;
end $$;
revoke all on function public.create_exchange_offer(uuid,uuid,uuid) from public,anon;
grant execute on function public.create_exchange_offer(uuid,uuid,uuid) to authenticated;

create or replace function public.submit_order_review(
  p_order_id uuid,p_rating smallint,p_comment text default null
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_seller uuid; v_id uuid;
begin
  select seller_profile_id into v_seller from public.orders
  where id=p_order_id and buyer_id=auth.uid() and status='delivered';
  if v_seller is null then raise exception 'REVIEW_NOT_ALLOWED'; end if;
  if p_rating not between 1 and 5 then raise exception 'INVALID_RATING'; end if;
  insert into public.reviews(order_id,reviewer_user_id,seller_profile_id,rating,comment)
  values(p_order_id,auth.uid(),v_seller,p_rating,nullif(trim(p_comment),'')) returning id into v_id;
  return v_id;
end $$;
revoke all on function public.submit_order_review(uuid,smallint,text) from public,anon;
grant execute on function public.submit_order_review(uuid,smallint,text) to authenticated;

-- Private dispute evidence and public product images use separate buckets.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values
 ('product-images','product-images',true,10485760,array['image/jpeg','image/png','image/webp']),
 ('dispute-evidence','dispute-evidence',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict(id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create policy product_images_object_read on storage.objects for select to anon,authenticated
using (bucket_id='product-images');
create policy product_images_object_insert on storage.objects for insert to authenticated
with check (
  bucket_id='product-images' and (storage.foldername(name))[1]='products'
  and (storage.foldername(name))[2]=auth.uid()::text
);
create policy product_images_object_delete on storage.objects for delete to authenticated
using (
  bucket_id='product-images' and (storage.foldername(name))[1]='products'
  and (storage.foldername(name))[2]=auth.uid()::text
);
create policy dispute_evidence_object_read on storage.objects for select to authenticated
using (
  bucket_id='dispute-evidence'
  and private.is_dispute_participant(((storage.foldername(name))[1])::uuid)
);
create policy dispute_evidence_object_insert on storage.objects for insert to authenticated
with check (
  bucket_id='dispute-evidence'
  and (storage.foldername(name))[2]=auth.uid()::text
  and private.is_dispute_participant(((storage.foldername(name))[1])::uuid)
);

