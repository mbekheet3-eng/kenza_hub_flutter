
-- Public seller profile data must not expose the owner's auth-linked UUID.
revoke select on public.seller_profiles from anon,authenticated;
grant select (id,seller_type,business_type,display_name,business_name,bio,avatar_url,verification_status,is_active,created_at,updated_at)
on public.seller_profiles to anon,authenticated;

create index if not exists user_blocks_blocked_user_idx on public.user_blocks(blocked_user_id);

-- Move privileged implementations out of the exposed API schema.
alter function public.create_seller_profile(text,text) set schema private;
alter function public.manage_seller_member(uuid,text,uuid,jsonb) set schema private;
alter function public.get_or_create_chat(uuid) set schema private;
alter function public.assign_delivery_courier(uuid,uuid,text) set schema private;
alter function public.get_my_delivery_details(uuid) set schema private;
alter function public.admin_transition_dispute(uuid,text,text,text) set schema private;
alter function public.submit_dispute_consent(uuid,text) set schema private;
alter function public.place_auction_bid(uuid,numeric) set schema private;
alter function public.create_exchange_offer(uuid,uuid,uuid) set schema private;
alter function public.submit_order_review(uuid,smallint,text) set schema private;

grant execute on function private.create_seller_profile(text,text) to authenticated;
grant execute on function private.manage_seller_member(uuid,text,uuid,jsonb) to authenticated;
grant execute on function private.get_or_create_chat(uuid) to authenticated;
grant execute on function private.assign_delivery_courier(uuid,uuid,text) to authenticated;
grant execute on function private.get_my_delivery_details(uuid) to authenticated;
grant execute on function private.admin_transition_dispute(uuid,text,text,text) to authenticated;
grant execute on function private.submit_dispute_consent(uuid,text) to authenticated;
grant execute on function private.place_auction_bid(uuid,numeric) to authenticated;
grant execute on function private.create_exchange_offer(uuid,uuid,uuid) to authenticated;
grant execute on function private.submit_order_review(uuid,smallint,text) to authenticated;

create function public.create_seller_profile(p_display_name text,p_bio text default null)
returns uuid language sql set search_path=''
as $$ select private.create_seller_profile($1,$2) $$;
create function public.manage_seller_member(p_seller_profile_id uuid,p_action text,p_member_user_id uuid,p_permissions jsonb default '{}'::jsonb)
returns void language sql set search_path=''
as $$ select private.manage_seller_member($1,$2,$3,$4) $$;
create function public.get_or_create_chat(p_product_id uuid)
returns uuid language sql set search_path=''
as $$ select private.get_or_create_chat($1) $$;
create function public.assign_delivery_courier(p_order_id uuid,p_courier_user_id uuid,p_reason text)
returns uuid language sql set search_path=''
as $$ select private.assign_delivery_courier($1,$2,$3) $$;
create function public.get_my_delivery_details(p_order_id uuid)
returns table(order_id uuid,recipient_name text,recipient_phone text,address_line_1 text,address_line_2 text,landmark text,region_id uuid,latitude numeric,longitude numeric,delivery_notes text)
language sql set search_path=''
as $$ select * from private.get_my_delivery_details($1) $$;
create function public.admin_transition_dispute(p_dispute_id uuid,p_new_status text,p_decision text,p_reason text)
returns void language sql set search_path=''
as $$ select private.admin_transition_dispute($1,$2,$3,$4) $$;
create function public.submit_dispute_consent(p_dispute_id uuid,p_proposed_status text)
returns uuid language sql set search_path=''
as $$ select private.submit_dispute_consent($1,$2) $$;
create function public.place_auction_bid(p_auction_id uuid,p_amount numeric)
returns uuid language sql set search_path=''
as $$ select private.place_auction_bid($1,$2) $$;
create function public.create_exchange_offer(p_target_seller_profile_id uuid,p_offered_product_id uuid,p_requested_product_id uuid)
returns uuid language sql set search_path=''
as $$ select private.create_exchange_offer($1,$2,$3) $$;
create function public.submit_order_review(p_order_id uuid,p_rating smallint,p_comment text default null)
returns uuid language sql set search_path=''
as $$ select private.submit_order_review($1,$2,$3) $$;

revoke all on function public.create_seller_profile(text,text) from public,anon;
revoke all on function public.manage_seller_member(uuid,text,uuid,jsonb) from public,anon;
revoke all on function public.get_or_create_chat(uuid) from public,anon;
revoke all on function public.assign_delivery_courier(uuid,uuid,text) from public,anon;
revoke all on function public.get_my_delivery_details(uuid) from public,anon;
revoke all on function public.admin_transition_dispute(uuid,text,text,text) from public,anon;
revoke all on function public.submit_dispute_consent(uuid,text) from public,anon;
revoke all on function public.place_auction_bid(uuid,numeric) from public,anon;
revoke all on function public.create_exchange_offer(uuid,uuid,uuid) from public,anon;
revoke all on function public.submit_order_review(uuid,smallint,text) from public,anon;
grant execute on function public.create_seller_profile(text,text) to authenticated;
grant execute on function public.manage_seller_member(uuid,text,uuid,jsonb) to authenticated;
grant execute on function public.get_or_create_chat(uuid) to authenticated;
grant execute on function public.assign_delivery_courier(uuid,uuid,text) to authenticated;
grant execute on function public.get_my_delivery_details(uuid) to authenticated;
grant execute on function public.admin_transition_dispute(uuid,text,text,text) to authenticated;
grant execute on function public.submit_dispute_consent(uuid,text) to authenticated;
grant execute on function public.place_auction_bid(uuid,numeric) to authenticated;
grant execute on function public.create_exchange_offer(uuid,uuid,uuid) to authenticated;
grant execute on function public.submit_order_review(uuid,smallint,text) to authenticated;

create or replace function private.admin_review_pro_seller_request(
  p_request_id uuid,p_decision text,p_review_note text default null
) returns void language plpgsql security definer set search_path=''
as $$
declare v_req public.pro_seller_upgrade_requests%rowtype;
begin
  if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
  if p_decision not in ('approved','rejected') then raise exception 'INVALID_DECISION'; end if;
  select * into v_req from public.pro_seller_upgrade_requests where id=p_request_id for update;
  if v_req.id is null or v_req.status<>'pending' then raise exception 'REQUEST_NOT_PENDING'; end if;
  update public.pro_seller_upgrade_requests set status=p_decision,reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_review_note where id=p_request_id;
  if p_decision='approved' then
    update public.seller_profiles set seller_type='pro_seller',business_type=coalesce(v_req.requested_business_type,'individual')
    where id=v_req.seller_profile_id;
  end if;
  insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,before_data,after_data)
  values(auth.uid(),'pro_seller.request_reviewed','pro_seller_upgrade_requests',p_request_id,p_review_note,
    jsonb_build_object('status','pending'),jsonb_build_object('status',p_decision,'business_type',v_req.requested_business_type));
end $$;
revoke all on function private.admin_review_pro_seller_request(uuid,text,text) from public,anon;
grant execute on function private.admin_review_pro_seller_request(uuid,text,text) to authenticated;
create function public.admin_review_pro_seller_request(p_request_id uuid,p_decision text,p_review_note text default null)
returns void language sql set search_path=''
as $$ select private.admin_review_pro_seller_request($1,$2,$3) $$;
revoke all on function public.admin_review_pro_seller_request(uuid,text,text) from public,anon;
grant execute on function public.admin_review_pro_seller_request(uuid,text,text) to authenticated;

-- Append-only records cannot be edited or removed, even by normal application code.
create or replace function private.reject_mutation()
returns trigger language plpgsql set search_path=''
as $$ begin raise exception 'APPEND_ONLY_RECORD'; end $$;
create trigger dispute_evidence_append_only before update or delete on public.dispute_evidence
for each row execute function private.reject_mutation();
create trigger admin_audit_append_only before update or delete on public.admin_audit_log
for each row execute function private.reject_mutation();

-- Followers can view follower-audience listings; other audiences remain owner-only.
drop policy if exists products_public_or_owner_read on public.products;
create policy products_public_or_owner_read on public.products for select to anon,authenticated using (
  (moderation_status='approved' and audience='public')
  or ((select auth.uid()) is not null and audience='followers' and moderation_status='approved'
      and exists(select 1 from public.follows f where f.follower_user_id=(select auth.uid()) and f.followed_seller_profile_id=seller_id))
  or ((select auth.uid()) is not null and private.has_seller_permission(seller_id,'products:read'))
  or ((select auth.uid()) is not null and private.is_admin())
);
