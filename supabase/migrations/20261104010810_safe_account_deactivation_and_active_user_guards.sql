alter table public.users add column deactivated_at timestamptz;

create or replace function private.is_admin()
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.users u where u.id=(select auth.uid()) and u.role='admin' and u.is_active) $$;
create or replace function private.is_seller_owner(p_profile_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$ select exists(select 1 from public.seller_profiles sp join public.users u on u.id=sp.owner_user_id
  where sp.id=p_profile_id and sp.owner_user_id=(select auth.uid()) and sp.is_active and u.is_active) $$;
create or replace function private.has_seller_permission(p_profile_id uuid,p_permission text)
returns boolean language sql stable security definer set search_path=''
as $$ select private.is_active_user() and exists(
  select 1 from public.seller_profile_members m
  join public.users u on u.id=m.user_id
  where m.seller_profile_id=p_profile_id and m.user_id=(select auth.uid())
    and m.revoked_at is null and u.is_active
    and (m.member_role='owner' or coalesce((m.permissions->>p_permission)::boolean,false))
) $$;
create or replace function private.is_dispute_participant(p_dispute_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select private.is_active_user() and exists(
  select 1 from public.disputes d join public.orders o on o.id=d.order_id
  where d.id=p_dispute_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id))
 )
$$;

create or replace function private.deactivate_my_account()
returns void language plpgsql security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid();
begin
  if v_uid is null or not private.is_active_user() then raise exception 'ACTIVE_SESSION_REQUIRED'; end if;
  update public.users set is_active=false,deactivated_at=now() where id=v_uid;
  insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,after_data)
  values(v_uid,'account.deactivated','users',v_uid,'User requested account deactivation',jsonb_build_object('is_active',false));
end $$;
revoke all on function private.deactivate_my_account() from public,anon;
grant execute on function private.deactivate_my_account() to authenticated;
create function public.deactivate_my_account()
returns void language sql set search_path=''
as $$ select private.deactivate_my_account() $$;
revoke all on function public.deactivate_my_account() from public,anon;
grant execute on function public.deactivate_my_account() to authenticated;

drop policy if exists users_read_self on public.users;
create policy users_read_self on public.users for select to authenticated using (id=(select auth.uid()) and private.is_active_user());
drop policy if exists users_update_self on public.users;
create policy users_update_self on public.users for update to authenticated using (id=(select auth.uid()) and private.is_active_user()) with check (id=(select auth.uid()) and private.is_active_user());
drop policy if exists seller_members_read_self_or_owner on public.seller_profile_members;
create policy seller_members_read_self_or_owner on public.seller_profile_members for select to authenticated using (
  private.is_active_user() and (user_id=(select auth.uid()) or private.is_seller_owner(seller_profile_id))
);
drop policy if exists addresses_owner_all on public.user_addresses;
create policy addresses_owner_all on public.user_addresses for all to authenticated
using (private.is_active_user() and user_id=(select auth.uid()))
with check (private.is_active_user() and user_id=(select auth.uid()));
drop policy if exists favorites_owner_all on public.favorites;
create policy favorites_owner_all on public.favorites for all to authenticated
using (private.is_active_user() and user_id=(select auth.uid()))
with check (private.is_active_user() and user_id=(select auth.uid()));
drop policy if exists follows_owner_all on public.follows;
create policy follows_owner_all on public.follows for all to authenticated
using (private.is_active_user() and follower_user_id=(select auth.uid()))
with check (private.is_active_user() and follower_user_id=(select auth.uid()));
drop policy if exists user_blocks_owner_all on public.user_blocks;
create policy user_blocks_owner_all on public.user_blocks for all to authenticated
using (private.is_active_user() and blocker_user_id=(select auth.uid()))
with check (private.is_active_user() and blocker_user_id=(select auth.uid()));
drop policy if exists orders_buyer_or_seller_owner_read on public.orders;
create policy orders_buyer_or_seller_owner_read on public.orders for select to authenticated using (
  private.is_active_user() and (buyer_id=(select auth.uid()) or private.is_seller_owner(seller_profile_id) or private.is_admin())
);
drop policy if exists delivery_assignments_courier_or_owner_read on public.delivery_assignments;
create policy delivery_assignments_courier_or_owner_read on public.delivery_assignments for select to authenticated using (
  private.is_active_user() and (courier_user_id=(select auth.uid()) or private.is_seller_owner((select o.seller_profile_id from public.orders o where o.id=order_id)) or private.is_admin())
);
drop policy if exists order_history_participant_read on public.order_status_history;
create policy order_history_participant_read on public.order_status_history for select to authenticated using (
  private.is_active_user() and exists(select 1 from public.orders o where o.id=order_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id)))
);
drop policy if exists disputes_participant_read on public.disputes;
create policy disputes_participant_read on public.disputes for select to authenticated using (
  private.is_active_user() and (private.is_dispute_participant(id) or private.is_admin())
);
drop policy if exists disputes_participant_insert on public.disputes;
create policy disputes_participant_insert on public.disputes for insert to authenticated with check (
  private.is_active_user() and opened_by=(select auth.uid()) and status='open' and private.is_dispute_participant(id)
);
drop policy if exists dispute_evidence_participant_read on public.dispute_evidence;
create policy dispute_evidence_participant_read on public.dispute_evidence for select to authenticated using (
  private.is_dispute_participant(dispute_id) or private.is_admin()
);
drop policy if exists dispute_evidence_participant_insert on public.dispute_evidence;
create policy dispute_evidence_participant_insert on public.dispute_evidence for insert to authenticated with check (
  private.is_active_user() and uploaded_by=(select auth.uid()) and private.is_dispute_participant(dispute_id)
);
drop policy if exists dispute_consents_read on public.dispute_status_consents;
create policy dispute_consents_read on public.dispute_status_consents for select to authenticated using (
  private.is_active_user() and (user_id=(select auth.uid()) or private.is_admin())
);
drop policy if exists chats_participant_read on public.chats;
create policy chats_participant_read on public.chats for select to authenticated using (
  private.is_active_user() and (buyer_id=(select auth.uid()) or private.is_seller_owner(seller_profile_id))
);
drop policy if exists notifications_owner_all on public.notifications;
create policy notifications_owner_all on public.notifications for all to authenticated
using (private.is_active_user() and user_id=(select auth.uid()))
with check (private.is_active_user() and user_id=(select auth.uid()));

drop policy if exists product_images_object_insert on storage.objects;
create policy product_images_object_insert on storage.objects for insert to authenticated
with check (
  bucket_id='product-images' and private.is_active_user()
  and (storage.foldername(name))[1]='products'
  and (storage.foldername(name))[2]=auth.uid()::text
);
drop policy if exists product_images_object_delete on storage.objects;
create policy product_images_object_delete on storage.objects for delete to authenticated
using (
  bucket_id='product-images' and private.is_active_user()
  and (storage.foldername(name))[1]='products'
  and (storage.foldername(name))[2]=auth.uid()::text
);

