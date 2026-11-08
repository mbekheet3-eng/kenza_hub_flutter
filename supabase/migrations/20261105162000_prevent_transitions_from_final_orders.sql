create or replace function public.advance_order_status(p_order_id uuid,p_next_status text,p_reason text default null)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.orders%rowtype;
  v_is_buyer boolean;
  v_is_seller boolean;
  v_is_courier boolean;
  v_is_admin boolean;
begin
  if auth.uid() is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.status in ('closed','cancelled') then raise exception 'ORDER_FINAL'; end if;
  v_is_buyer := v_order.buyer_id=auth.uid();
  v_is_seller := private.is_seller_owner(v_order.seller_profile_id);
  v_is_admin := private.is_admin();
  v_is_courier := exists(select 1 from public.delivery_assignments a where a.order_id=p_order_id
    and a.courier_user_id=auth.uid() and a.ended_at is null and a.status in ('assigned','accepted','in_transit'));
  if p_next_status='cancelled' then
    if not (v_is_admin or v_is_buyer or v_is_seller) then raise exception 'NOT_AUTHORIZED'; end if;
    if v_order.status not in ('pending_agreement','confirmed') and not v_is_admin then raise exception 'CANCELLATION_NOT_ALLOWED'; end if;
    if nullif(trim(p_reason),'') is null then raise exception 'REASON_REQUIRED'; end if;
  elsif v_order.status='confirmed' and p_next_status='processing' then
    if not (v_is_seller or v_is_admin) then raise exception 'SELLER_OR_ADMIN_REQUIRED'; end if;
  elsif v_order.status='processing' and p_next_status='shipped' then
    if not (v_is_seller or v_is_admin) then raise exception 'SELLER_OR_ADMIN_REQUIRED'; end if;
  elsif v_order.status='shipped' and p_next_status='delivered' then
    if not (v_is_courier or v_is_admin) then raise exception 'ASSIGNED_COURIER_OR_ADMIN_REQUIRED'; end if;
  elsif v_order.status='delivered' and p_next_status='closed' then
    if v_is_buyer then
      update public.orders set buyer_received_at=coalesce(buyer_received_at,now()) where id=p_order_id;
    elsif v_is_admin and v_order.delivery_review_required_at is not null then
      if length(trim(coalesce(p_reason,''))) < 8 then raise exception 'AUDIT_REASON_REQUIRED'; end if;
      insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason)
      values(auth.uid(),'order.closed_after_delivery_review','orders',p_order_id,trim(p_reason));
    else raise exception 'BUYER_CONFIRMATION_OR_ADMIN_REVIEW_REQUIRED';
    end if;
  else raise exception 'INVALID_ORDER_TRANSITION';
  end if;
  perform set_config('kenza.order_transition_reason',coalesce(nullif(trim(p_reason),''),''),true);
  update public.orders set status=p_next_status,
    courier_delivered_at=case when p_next_status='delivered' then now() else courier_delivered_at end,
    delivery_review_required_at=case when p_next_status='closed' then null else delivery_review_required_at end
    where id=p_order_id;
  if p_next_status='delivered' and v_is_courier then
    update public.delivery_assignments set status='delivered',ended_at=now()
      where order_id=p_order_id and courier_user_id=auth.uid() and ended_at is null;
  end if;
  return p_next_status;
end;
$$;
revoke all on function public.advance_order_status(uuid,text,text) from public, anon;
grant execute on function public.advance_order_status(uuid,text,text) to authenticated;
