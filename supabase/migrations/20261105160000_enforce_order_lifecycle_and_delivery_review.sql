alter table public.orders
  add column if not exists courier_delivered_at timestamptz,
  add column if not exists buyer_received_at timestamptz,
  add column if not exists delivery_review_required_at timestamptz;

create or replace function private.log_order_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_role text;
begin
  if tg_op = 'INSERT' then
    select u.role into v_role from public.users u where u.id = new.buyer_id;
    insert into public.order_status_history(order_id, previous_status, new_status, action, actor_id, actor_role, metadata)
    values (new.id, null, new.status, 'order_created', auth.uid(), coalesce(v_role,'system'), jsonb_build_object('source','database_trigger'));
    return new;
  end if;
  if new.status is distinct from old.status then
    select u.role into v_role from public.users u where u.id = auth.uid();
    insert into public.order_status_history(order_id, previous_status, new_status, action, actor_id, actor_role, reason, metadata)
    values (new.id, old.status, new.status, 'status_transition', auth.uid(),
      coalesce(v_role, case when auth.uid() is null then 'system' else 'unknown' end),
      nullif(current_setting('kenza.order_transition_reason', true),''),
      jsonb_build_object('changed_at', now()));
  end if;
  return new;
end;
$$;

drop trigger if exists orders_status_history_log on public.orders;
create trigger orders_status_history_log
after insert or update of status on public.orders
for each row execute function private.log_order_status_change();

create or replace function public.confirm_order_agreement(p_order_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare v_order public.orders%rowtype; v_is_buyer boolean; v_is_seller boolean;
begin
  if auth.uid() is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  v_is_buyer := v_order.buyer_id = auth.uid();
  v_is_seller := private.is_seller_owner(v_order.seller_profile_id);
  if not (v_is_buyer or v_is_seller or private.is_admin()) then raise exception 'NOT_AUTHORIZED'; end if;
  if v_order.status <> 'pending_agreement' then raise exception 'AGREEMENT_NOT_PENDING'; end if;
  if v_order.agreement_snapshot is null or nullif(trim(v_order.agreement_version),'') is null
     or v_order.agreed_unit_price is null then raise exception 'AGREEMENT_DETAILS_INCOMPLETE'; end if;
  if v_is_buyer then
    update public.orders set buyer_confirmed_at=coalesce(buyer_confirmed_at,now()) where id=p_order_id;
  elsif v_is_seller then
    update public.orders set seller_confirmed_at=coalesce(seller_confirmed_at,now()) where id=p_order_id;
  else raise exception 'ADMIN_CANNOT_CONFIRM_FOR_PARTIES';
  end if;
  update public.orders set status='confirmed', agreement_confirmed_at=now()
    where id=p_order_id and buyer_confirmed_at is not null and seller_confirmed_at is not null;
  if exists(select 1 from public.orders where id=p_order_id and status='confirmed') then return 'confirmed'; end if;
  return 'waiting_for_other_party';
end;
$$;

create or replace function public.advance_order_status(p_order_id uuid,p_next_status text,p_reason text default null)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare v_order public.orders%rowtype; v_is_buyer boolean; v_is_seller boolean; v_is_courier boolean; v_is_admin boolean;
begin
  if auth.uid() is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
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

create or replace function private.mark_orders_for_delivery_review()
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare v_count bigint;
begin
  with due as (
    update public.orders set delivery_review_required_at=now()
    where status='delivered' and courier_delivered_at is not null
      and courier_delivered_at <= now()-interval '48 hours'
      and buyer_received_at is null and delivery_review_required_at is null
    returning id
  )
  insert into public.order_status_history(order_id,previous_status,new_status,action,actor_role,reason,metadata)
  select id,'delivered','delivered','buyer_confirmation_timeout_review_required','system',
    'Buyer did not confirm receipt within 48 hours',jsonb_build_object('review_required_at',now())
  from due;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.confirm_order_agreement(uuid) from public, anon;
revoke all on function public.advance_order_status(uuid,text,text) from public, anon;
grant execute on function public.confirm_order_agreement(uuid) to authenticated;
grant execute on function public.advance_order_status(uuid,text,text) to authenticated;
revoke all on function private.mark_orders_for_delivery_review() from public, anon, authenticated;
grant execute on function private.mark_orders_for_delivery_review() to postgres, service_role;

select cron.schedule('order-delivery-review-timeout-hourly','0 * * * *','select private.mark_orders_for_delivery_review();');
