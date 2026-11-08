create or replace function private.increment_product_views(p_product_id uuid)
returns bigint language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_inserted integer;
begin
 if v_uid is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 if not exists(
   select 1 from public.products p
   where p.id=p_product_id and p.moderation_status='approved'
     and (p.audience='public' or (p.audience='followers' and exists(
       select 1 from public.follows f where f.follower_user_id=v_uid and f.followed_seller_profile_id=p.seller_id
     )))
 ) then raise exception 'PRODUCT_NOT_AVAILABLE'; end if;
 insert into public.product_view_events(product_id,viewer_user_id,viewed_on)
 values(p_product_id,v_uid,current_date)
 on conflict(product_id,viewer_user_id,viewed_on) do nothing;
 get diagnostics v_inserted = row_count;
 if v_inserted=1 then update public.products set views_count=views_count+1 where id=p_product_id; end if;
 return (select views_count from public.products where id=p_product_id);
end $$;

create or replace function private.edit_product(
 p_product_id uuid,p_category_id uuid,p_title_ar text,p_title_en text,p_description_ar text,p_description_en text,
 p_price numeric,p_condition_id uuid,p_color_id uuid,p_size_id uuid,p_brand_name text,p_weight_kg numeric,p_audience text
) returns void language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_pending uuid;
begin
 select seller_id into v_seller from public.products where id=p_product_id for update;
 if v_seller is null then raise exception 'PRODUCT_NOT_FOUND'; end if;
 if not private.has_seller_permission(v_seller,'products:update') then raise exception 'PRODUCT_UPDATE_PERMISSION_REQUIRED'; end if;
 if not private.is_seller_in_service_area(v_seller) then raise exception 'OUTSIDE_DELIVERY_COVERAGE'; end if;
 if not exists(select 1 from public.categories where id=p_category_id and is_active) then raise exception 'INVALID_CATEGORY'; end if;
 if p_price<=0 or (p_weight_kg is not null and (p_weight_kg<0 or p_weight_kg>10)) then raise exception 'INVALID_PRODUCT_DATA'; end if;
 if p_audience not in ('public','followers','private') then raise exception 'INVALID_AUDIENCE'; end if;
 select id into v_pending from public.product_statuses where slug='pending_review';
 update public.products set category_id=p_category_id,title_ar=trim(p_title_ar),title_en=nullif(trim(p_title_en),''),
   description_ar=p_description_ar,description_en=p_description_en,price=p_price,condition_id=p_condition_id,
   color_id=p_color_id,size_id=p_size_id,brand_name=nullif(trim(p_brand_name),''),weight_kg=p_weight_kg,
   audience=p_audience,moderation_status='pending',status_id=v_pending,published_at=null
 where id=p_product_id;
end $$;
revoke all on function private.edit_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) from public,anon;
grant execute on function private.edit_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) to authenticated;
create function public.edit_product(
 p_product_id uuid,p_category_id uuid,p_title_ar text,p_title_en text,p_description_ar text,p_description_en text,
 p_price numeric,p_condition_id uuid,p_color_id uuid default null,p_size_id uuid default null,
 p_brand_name text default null,p_weight_kg numeric default null,p_audience text default 'public'
) returns void language sql set search_path=''
as $$ select private.edit_product($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) $$;
revoke all on function public.edit_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) from public,anon;
grant execute on function public.edit_product(uuid,uuid,text,text,text,text,numeric,uuid,uuid,uuid,text,numeric,text) to authenticated;

create or replace function private.archive_product(p_product_id uuid)
returns void language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_hidden uuid;
begin
 select seller_id into v_seller from public.products where id=p_product_id for update;
 if v_seller is null then raise exception 'PRODUCT_NOT_FOUND'; end if;
 if not private.has_seller_permission(v_seller,'products:delete') then raise exception 'PRODUCT_DELETE_PERMISSION_REQUIRED'; end if;
 select id into v_hidden from public.product_statuses where slug='hidden';
 update public.products set moderation_status='hidden',status_id=v_hidden,published_at=null where id=p_product_id;
end $$;
revoke all on function private.archive_product(uuid) from public,anon;
grant execute on function private.archive_product(uuid) to authenticated;
create function public.archive_product(p_product_id uuid)
returns void language sql set search_path=''
as $$ select private.archive_product($1) $$;
revoke all on function public.archive_product(uuid) from public,anon;
grant execute on function public.archive_product(uuid) to authenticated;

create or replace function private.create_auction(
 p_product_id uuid,p_starting_price numeric,p_minimum_increment numeric,p_starts_at timestamptz,p_ends_at timestamptz
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_id uuid; v_status text;
begin
 select seller_id into v_seller from public.products where id=p_product_id and moderation_status='approved' and audience='public';
 if v_seller is null then raise exception 'PRODUCT_NOT_AVAILABLE_FOR_AUCTION'; end if;
 if not private.has_seller_permission(v_seller,'products:update') then raise exception 'AUCTION_CREATE_PERMISSION_REQUIRED'; end if;
 if p_starting_price<=0 or p_minimum_increment<=0 or p_ends_at<=p_starts_at or p_starts_at<now() then raise exception 'INVALID_AUCTION_TERMS'; end if;
 v_status:=case when p_starts_at<=now() then 'live' else 'scheduled' end;
 insert into public.auctions(product_id,seller_profile_id,starting_price,minimum_increment,starts_at,ends_at,status)
 values(p_product_id,v_seller,p_starting_price,p_minimum_increment,p_starts_at,p_ends_at,v_status)
 returning id into v_id;
 return v_id;
end $$;
revoke all on function private.create_auction(uuid,numeric,numeric,timestamptz,timestamptz) from public,anon;
grant execute on function private.create_auction(uuid,numeric,numeric,timestamptz,timestamptz) to authenticated;
create function public.create_auction(p_product_id uuid,p_starting_price numeric,p_minimum_increment numeric,p_starts_at timestamptz,p_ends_at timestamptz)
returns uuid language sql set search_path=''
as $$ select private.create_auction($1,$2,$3,$4,$5) $$;
revoke all on function public.create_auction(uuid,numeric,numeric,timestamptz,timestamptz) from public,anon;
grant execute on function public.create_auction(uuid,numeric,numeric,timestamptz,timestamptz) to authenticated;

create or replace function private.respond_exchange_offer(p_offer_id uuid,p_decision text)
returns void language plpgsql security definer set search_path=''
as $$
declare v_target uuid;
begin
 if p_decision not in ('accepted','rejected') then raise exception 'INVALID_DECISION'; end if;
 select target_seller_profile_id into v_target from public.exchange_offers where id=p_offer_id and status='pending' for update;
 if v_target is null then raise exception 'OFFER_NOT_PENDING'; end if;
 if not private.has_seller_permission(v_target,'exchange:manage') then raise exception 'TARGET_OWNER_PERMISSION_REQUIRED'; end if;
 if not exists(select 1 from public.seller_profiles where id=v_target and seller_type='pro_seller') then raise exception 'PRO_SELLER_ONLY'; end if;
 update public.exchange_offers set status=p_decision where id=p_offer_id;
end $$;
revoke all on function private.respond_exchange_offer(uuid,text) from public,anon;
grant execute on function private.respond_exchange_offer(uuid,text) to authenticated;
create function public.respond_exchange_offer(p_offer_id uuid,p_decision text)
returns void language sql set search_path=''
as $$ select private.respond_exchange_offer($1,$2) $$;
revoke all on function public.respond_exchange_offer(uuid,text) from public,anon;
grant execute on function public.respond_exchange_offer(uuid,text) to authenticated;

create or replace function private.add_dispute_evidence(p_dispute_id uuid,p_storage_path text,p_caption text default null)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if not private.is_dispute_participant(p_dispute_id) then raise exception 'NOT_A_DISPUTE_PARTICIPANT'; end if;
 if p_storage_path !~ ('^'||p_dispute_id::text||'/'||auth.uid()::text||'/[^/]+$') then raise exception 'INVALID_EVIDENCE_PATH'; end if;
 if not exists(select 1 from storage.objects where bucket_id='dispute-evidence' and name=p_storage_path) then raise exception 'EVIDENCE_OBJECT_NOT_FOUND'; end if;
 insert into public.dispute_evidence(dispute_id,uploaded_by,storage_path,caption)
 values(p_dispute_id,auth.uid(),p_storage_path,nullif(trim(p_caption),'')) returning id into v_id;
 return v_id;
end $$;
revoke all on function private.add_dispute_evidence(uuid,text,text) from public,anon;
grant execute on function private.add_dispute_evidence(uuid,text,text) to authenticated;
create function public.add_dispute_evidence(p_dispute_id uuid,p_storage_path text,p_caption text default null)
returns uuid language sql set search_path=''
as $$ select private.add_dispute_evidence($1,$2,$3) $$;
revoke all on function public.add_dispute_evidence(uuid,text,text) from public,anon;
grant execute on function public.add_dispute_evidence(uuid,text,text) to authenticated;
revoke insert on public.dispute_evidence from authenticated;

create or replace view public.agency_directory with (security_invoker=true) as
select id,display_name,business_name,bio,avatar_url,verification_status,created_at
from public.seller_profiles where is_active and business_type='agency';
create or replace view public.online_store_directory with (security_invoker=true) as
select id,display_name,business_name,bio,avatar_url,verification_status,created_at
from public.seller_profiles where is_active and business_type='online_store';
grant select on public.agency_directory,public.online_store_directory to anon,authenticated;

create index if not exists product_view_events_viewer_idx on public.product_view_events(viewer_user_id);
create index if not exists product_view_events_product_date_idx on public.product_view_events(product_id,viewed_on desc);

