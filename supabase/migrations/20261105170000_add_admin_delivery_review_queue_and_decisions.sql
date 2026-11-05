create table if not exists public.order_delivery_reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  reviewed_by uuid not null references public.users(id) on delete restrict,
  action text not null check (action in ('kept_pending','dispute_opened','order_closed')),
  reason text not null check (char_length(trim(reason)) >= 8),
  created_at timestamptz not null default now()
);

alter table public.order_delivery_reviews enable row level security;
drop policy if exists order_delivery_reviews_admin_read on public.order_delivery_reviews;
create policy order_delivery_reviews_admin_read on public.order_delivery_reviews
for select to authenticated using (private.is_active_user() and private.is_admin());
drop trigger if exists order_delivery_reviews_append_only on public.order_delivery_reviews;
create trigger order_delivery_reviews_append_only before update or delete
on public.order_delivery_reviews for each row execute function private.reject_mutation();
revoke all on public.order_delivery_reviews from anon,authenticated;
grant select on public.order_delivery_reviews to authenticated;

create or replace function public.admin_get_delivery_review_queue()
returns table (
  order_id uuid, order_number text, order_status text,
  courier_delivered_at timestamptz, review_required_at timestamptz,
  buyer_received_at timestamptz, seller_name text, evidence_count bigint,
  active_dispute_id uuid, status_history jsonb
)
language plpgsql security definer set search_path = ''
as $$
begin
  if not private.is_active_user() or not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
  return query
  select o.id,o.order_number,o.status,o.courier_delivered_at,o.delivery_review_required_at,
    o.buyer_received_at,coalesce(sp.business_name,sp.display_name,'Seller')::text,
    (select count(*) from public.dispute_evidence e join public.disputes d on d.id=e.dispute_id where d.order_id=o.id),
    (select d.id from public.disputes d where d.order_id=o.id and d.status in ('open','under_review','awaiting_response') order by d.created_at desc limit 1),
    coalesce((select jsonb_agg(jsonb_build_object('previous_status',h.previous_status,'new_status',h.new_status,
      'action',h.action,'actor_role',h.actor_role,'reason',h.reason,'created_at',h.created_at)
      order by h.created_at) from public.order_status_history h where h.order_id=o.id),'[]'::jsonb)
  from public.orders o left join public.seller_profiles sp on sp.id=o.seller_profile_id
  where o.delivery_review_required_at is not null and o.status='delivered'
  order by o.delivery_review_required_at asc;
end;
$$;

create or replace function public.admin_decide_delivery_review(p_order_id uuid,p_action text,p_reason text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare v_order public.orders%rowtype; v_dispute_id uuid; v_review_id uuid;
begin
  if not private.is_active_user() or not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
  if p_action not in ('keep_pending','open_dispute','close_order') then raise exception 'INVALID_REVIEW_ACTION'; end if;
  if p_reason is null or char_length(trim(p_reason)) < 8 then raise exception 'AUDIT_REASON_REQUIRED'; end if;
  select * into v_order from public.orders where id=p_order_id for update;
  if not found then raise exception 'ORDER_NOT_FOUND'; end if;
  if v_order.status <> 'delivered' or v_order.delivery_review_required_at is null then raise exception 'ORDER_NOT_IN_DELIVERY_REVIEW'; end if;

  if p_action='keep_pending' then
    insert into public.order_delivery_reviews(order_id,reviewed_by,action,reason)
    values(p_order_id,auth.uid(),'kept_pending',trim(p_reason)) returning id into v_review_id;
    insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,before_data,after_data)
    values(auth.uid(),'order.delivery_review_kept_pending','orders',p_order_id,trim(p_reason),
      jsonb_build_object('status',v_order.status,'review_required_at',v_order.delivery_review_required_at),
      jsonb_build_object('status','delivered','review_required',true));
    return v_review_id;
  elsif p_action='open_dispute' then
    if exists(select 1 from public.disputes d where d.order_id=p_order_id and d.status in ('open','under_review','awaiting_response')) then raise exception 'ACTIVE_DISPUTE_ALREADY_EXISTS'; end if;
    insert into public.disputes(order_id,opened_by,status,reason,description)
    values(p_order_id,auth.uid(),'open','Administrative delivery review',trim(p_reason)) returning id into v_dispute_id;
    update public.orders set status='disputed' where id=p_order_id;
    insert into public.order_delivery_reviews(order_id,reviewed_by,action,reason)
    values(p_order_id,auth.uid(),'dispute_opened',trim(p_reason)) returning id into v_review_id;
    insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,after_data)
    values(auth.uid(),'order.delivery_review_dispute_opened','orders',p_order_id,trim(p_reason),jsonb_build_object('dispute_id',v_dispute_id));
    return v_review_id;
  else
    perform public.advance_order_status(p_order_id,'closed',trim(p_reason));
    insert into public.order_delivery_reviews(order_id,reviewed_by,action,reason)
    values(p_order_id,auth.uid(),'order_closed',trim(p_reason)) returning id into v_review_id;
    return v_review_id;
  end if;
end;
$$;

revoke all on function public.admin_get_delivery_review_queue() from public,anon;
grant execute on function public.admin_get_delivery_review_queue() to authenticated;
revoke all on function public.admin_decide_delivery_review(uuid,text,text) from public,anon;
grant execute on function public.admin_decide_delivery_review(uuid,text,text) to authenticated;
