create or replace function public.request_order_postponement(p_order_id uuid,p_requested_until timestamptz)
returns void language plpgsql security definer set search_path to ''
as $function$
declare v_order public.product_orders%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select * into v_order from public.product_orders where id=p_order_id for update;
  if not found or v_order.buyer_id<>auth.uid() then raise exception 'Order not found or not accessible' using errcode='42501'; end if;
  if v_order.status<>'accepted' or v_order.hold_expires_at<=now() then raise exception 'Order is not eligible for postponement' using errcode='23514'; end if;
  if v_order.postponement_extension_count>=1 or v_order.postponement_requested_at is not null then raise exception 'Only one postponement request is allowed' using errcode='23514'; end if;
  if p_requested_until<=v_order.hold_expires_at or p_requested_until>now()+interval '7 days' then raise exception 'Requested deadline must extend the current hold by no more than 7 days' using errcode='23514'; end if;
  update public.product_orders set postponement_requested_at=now(),postponement_requested_until=p_requested_until where id=p_order_id;
  perform public.create_user_notification(v_order.seller_id,'order_updated','طلب تأجيل طلب الشراء','طلب المشتري تمديد مهلة الحجز. يرجى مراجعة الطلب.',jsonb_build_object('order_id',p_order_id),'order:'||p_order_id::text||':postponement-request');
end;
$function$;

create or replace function public.respond_order_postponement(p_order_id uuid,p_approve boolean)
returns void language plpgsql security definer set search_path to ''
as $function$
declare v_order public.product_orders%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select * into v_order from public.product_orders where id=p_order_id for update;
  if not found or v_order.seller_id<>auth.uid() then raise exception 'Order not found or not accessible' using errcode='42501'; end if;
  if v_order.status<>'accepted' or v_order.postponement_requested_at is null or v_order.hold_expires_at<=now() then raise exception 'No active postponement request' using errcode='23514'; end if;
  update public.product_orders set hold_expires_at=case when p_approve then v_order.postponement_requested_until else hold_expires_at end,
    postponement_extension_count=postponement_extension_count+case when p_approve then 1 else 0 end,
    postponement_requested_at=null,postponement_requested_until=null where id=p_order_id;
  perform public.create_user_notification(v_order.buyer_id,'order_updated',
    case when p_approve then 'تمت الموافقة على التأجيل' else 'لم يوافق البائع على التأجيل' end,
    case when p_approve then 'وافق البائع على تمديد مهلة الحجز.' else 'رفض البائع تمديد مهلة الحجز. ما زالت المهلة الأصلية سارية.' end,
    jsonb_build_object('order_id',p_order_id),'order:'||p_order_id::text||case when p_approve then ':postponement-approved' else ':postponement-declined' end);
end;
$function$;

create or replace function public.cancel_accepted_order(p_order_id uuid,p_reason text,p_note text default null)
returns void language plpgsql security definer set search_path to ''
as $function$
declare v_order public.product_orders%rowtype; v_is_buyer boolean;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select * into v_order from public.product_orders where id=p_order_id for update;
  if not found or auth.uid() not in (v_order.buyer_id,v_order.seller_id) then raise exception 'Order not found or not accessible' using errcode='42501'; end if;
  if v_order.status<>'accepted' then raise exception 'Only accepted orders can be cancelled through this action' using errcode='23514'; end if;
  v_is_buyer:=auth.uid()=v_order.buyer_id;
  if v_is_buyer then
    if p_reason<>'buyer_request' then raise exception 'Invalid buyer cancellation reason' using errcode='23514'; end if;
  else
    if p_reason not in ('item_damaged','item_missing','stock_error') or p_note is null or length(btrim(p_note))<8 then
      raise exception 'Seller cancellation requires a valid reason and an explanation' using errcode='23514'; end if;
  end if;
  update public.product_orders set status='cancelled',cancellation_reason=p_reason,cancellation_note=nullif(btrim(p_note),'') where id=p_order_id;
end;
$function$;
revoke all on function public.request_order_postponement(uuid,timestamptz) from public,anon;
revoke all on function public.respond_order_postponement(uuid,boolean) from public,anon;
revoke all on function public.cancel_accepted_order(uuid,text,text) from public,anon;
grant execute on function public.request_order_postponement(uuid,timestamptz) to authenticated;
grant execute on function public.respond_order_postponement(uuid,boolean) to authenticated;
grant execute on function public.cancel_accepted_order(uuid,text,text) to authenticated;