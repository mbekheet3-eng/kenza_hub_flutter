alter table public.product_orders
  add column if not exists hold_expires_at timestamptz,
  add column if not exists postponement_requested_at timestamptz,
  add column if not exists postponement_requested_until timestamptz,
  add column if not exists postponement_extension_count integer not null default 0,
  add column if not exists stock_restored_at timestamptz,
  add column if not exists cancellation_reason text,
  add column if not exists cancellation_note text;
alter table public.products add column if not exists reserved_by_order_id uuid;
create index if not exists product_orders_accepted_hold_expiry_idx on public.product_orders (hold_expires_at) where status = 'accepted';

create or replace function public.validate_product_order_status_transition()
returns trigger language plpgsql set search_path to ''
as $function$
declare v_owner_id uuid; v_price numeric; v_currency text; v_product_status text; v_has_variants boolean; v_rows integer;
begin
  if new.status is distinct from old.status then
    if not ((old.status='pending' and new.status in ('accepted','rejected','cancelled','expired'))
      or (old.status='accepted' and new.status in ('cancelled','expired','delivered'))
      or (old.status='delivered' and new.status='completed')) then
      raise exception 'Invalid purchase-order status transition: % -> %',old.status,new.status using errcode='23514';
    end if;
    if new.status='accepted' then
      select p.owner_id,p.price,p.currency,p.status,p.has_variants into v_owner_id,v_price,v_currency,v_product_status,v_has_variants
      from public.products p where p.id=new.product_id for update;
      if not found or v_product_status<>'published' or v_owner_id<>new.seller_id or v_price*new.quantity<>new.agreed_price
        or v_currency<>new.currency or v_has_variants<>(new.variant_id is not null) then
        raise exception 'The product price or availability changed; refresh the listing before accepting' using errcode='23514';
      end if;
      if new.variant_id is not null then
        update public.product_variants set quantity=quantity-new.quantity
        where id=new.variant_id and product_id=new.product_id and quantity>=new.quantity;
        get diagnostics v_rows=row_count;
        if v_rows=0 then raise exception 'out_of_stock' using errcode='23514'; end if;
      else
        update public.products set status='archived',reserved_by_order_id=new.id
        where id=new.product_id and owner_id=new.seller_id and status='published' and reserved_by_order_id is null;
        get diagnostics v_rows=row_count;
        if v_rows=0 then raise exception 'out_of_stock' using errcode='23514'; end if;
      end if;
      new.hold_expires_at:=now()+interval '24 hours';
      new.postponement_requested_at:=null; new.postponement_requested_until:=null;
      new.postponement_extension_count:=0; new.stock_restored_at:=null;
      new.cancellation_reason:=null; new.cancellation_note:=null;
    elsif old.status='accepted' and new.status in ('cancelled','expired') then
      if old.stock_restored_at is null then
        if old.variant_id is not null then
          update public.product_variants set quantity=quantity+old.quantity where id=old.variant_id and product_id=old.product_id;
        else
          update public.products set status='published',reserved_by_order_id=null
          where id=old.product_id and reserved_by_order_id=old.id and status='archived';
        end if;
        new.stock_restored_at:=now();
      end if;
      new.postponement_requested_at:=null; new.postponement_requested_until:=null;
    elsif old.status='accepted' and new.status='delivered' then
      if old.variant_id is null then
        update public.products set reserved_by_order_id=null where id=old.product_id and reserved_by_order_id=old.id;
      end if;
      new.postponement_requested_at:=null; new.postponement_requested_until:=null;
    end if;
  end if;
  new.updated_at:=now();
  return new;
end;
$function$;

create or replace function public.request_order_postponement(p_order_id uuid,p_requested_until timestamptz)
returns void language plpgsql security definer set search_path to ''
as $function$
declare v_order public.product_orders%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select * into v_order from public.product_orders where id=p_order_id for update;
  if not found or v_order.buyer_id<>auth.uid() then raise exception 'Order not found or not accessible' using errcode='42501'; end if;
  if v_order.status<>'accepted' or v_order.hold_expires_at<=now() then raise exception 'Order is not eligible for postponement' using errcode='23514'; end if;
  if v_order.postponement_extension_count>=1 or v_order.postponement_requested_at is not null then
    raise exception 'Only one postponement request is allowed' using errcode='23514';
  end if;
  if p_requested_until<=v_order.hold_expires_at or p_requested_until>now()+interval '7 days' then
    raise exception 'Requested deadline must extend the current hold by no more than 7 days' using errcode='23514';
  end if;
  update public.product_orders set postponement_requested_at=now(),postponement_requested_until=p_requested_until where id=p_order_id;
  perform public.create_user_notification(v_order.seller_id,'order_updated','طلب تأجيل طلب الشراء',
    'طلب المشتري تمديد مهلة الحجز. يرجى مراجعة الطلب.',jsonb_build_object('order_id',p_order_id),
    'order:'||p_order_id::text||':postponement-request');
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
  if v_order.status<>'accepted' or v_order.postponement_requested_at is null or v_order.hold_expires_at<=now() then
    raise exception 'No active postponement request' using errcode='23514';
  end if;
  update public.product_orders
  set hold_expires_at=case when p_approve then v_order.postponement_requested_until else hold_expires_at end,
      postponement_extension_count=postponement_extension_count+case when p_approve then 1 else 0 end,
      postponement_requested_at=null,postponement_requested_until=null
  where id=p_order_id;
  perform public.create_user_notification(v_order.buyer_id,
    case when p_approve then 'order_updated' else 'order_updated' end,
    case when p_approve then 'تمت الموافقة على التأجيل' else 'لم يوافق البائع على التأجيل' end,
    case when p_approve then 'وافق البائع على تمديد مهلة الحجز.' else 'رفض البائع تمديد مهلة الحجز. ما زالت المهلة الأصلية سارية.' end,
    jsonb_build_object('order_id',p_order_id),
    'order:'||p_order_id::text||case when p_approve then ':postponement-approved' else ':postponement-declined' end);
end;
$function$;

create or replace function public.cancel_accepted_order(p_order_id uuid,p_reason text,p_note text default null)
returns void language plpgsql security definer set search_path to ''
as $function$
declare v_order public.product_orders%rowtype; v_is_buyer boolean;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select * into v_order from public.product_orders where id=p_order_id for update;
  if not found or auth.uid() not in (v_order.buyer_id,v_order.seller_id) then
    raise exception 'Order not found or not accessible' using errcode='42501';
  end if;
  if v_order.status<>'accepted' then raise exception 'Only accepted orders can be cancelled through this action' using errcode='23514'; end if;
  v_is_buyer:=auth.uid()=v_order.buyer_id;
  if v_is_buyer then
    if p_reason<>'buyer_request' then raise exception 'Invalid buyer cancellation reason' using errcode='23514'; end if;
  else
    if p_reason not in ('item_damaged','item_missing','stock_error') or p_note is null or length(btrim(p_note))<8 then
      raise exception 'Seller cancellation requires a valid reason and an explanation' using errcode='23514';
    end if;
  end if;
  update public.product_orders set status='cancelled',cancellation_reason=p_reason,cancellation_note=nullif(btrim(p_note),'') where id=p_order_id;
  if not v_is_buyer then
    perform public.create_user_notification(v_order.buyer_id,'order_updated','ألغى البائع طلب الشراء',
      'ألغى البائع الطلب لسبب متعلق بتوفر المنتج أو حالته.',jsonb_build_object('order_id',p_order_id,'reason',p_reason),
      'order:'||p_order_id::text||':seller-cancelled');
  end if;
end;
$function$;

revoke all on function public.request_order_postponement(uuid,timestamptz) from public,anon;
revoke all on function public.respond_order_postponement(uuid,boolean) from public,anon;
revoke all on function public.cancel_accepted_order(uuid,text,text) from public,anon;
grant execute on function public.request_order_postponement(uuid,timestamptz) to authenticated;
grant execute on function public.respond_order_postponement(uuid,boolean) to authenticated;
grant execute on function public.cancel_accepted_order(uuid,text,text) to authenticated;

create or replace function public.process_pending_product_orders()
returns void language plpgsql security definer set search_path to ''
as $function$
begin
  update public.product_orders set status='expired',updated_at=now() where status='pending' and expires_at<=now();
  update public.product_orders set status='expired',updated_at=now()
  where status='accepted' and hold_expires_at is not null and hold_expires_at<=now();
  with due as (
    update public.product_orders set reminder_sent_at=now()
    where status='pending' and created_at<=now()-interval '24 hours' and expires_at>now() and reminder_sent_at is null
    returning id,product_id,seller_id
  )
  insert into public.notifications(user_id,type,title,body,data,event_key)
  select seller_id,'order_reminder','تذكير بطلب شراء معلق','لديك طلب شراء ينتظر ردك منذ 24 ساعة',
    jsonb_build_object('order_id',id,'product_id',product_id),'order:'||id::text||':reminder'
  from due on conflict(event_key) do nothing;
end;
$function$;

update public.products p set status='archived',reserved_by_order_id=o.id
from public.product_orders o
where o.product_id=p.id and o.status='accepted' and o.variant_id is null
  and p.status='published' and p.reserved_by_order_id is null;
update public.product_orders set hold_expires_at=now()+interval '24 hours'
where status='accepted' and hold_expires_at is null;

create or replace function public.notify_order_activity()
returns trigger language plpgsql security definer set search_path to ''
as $function$
begin
  if TG_OP='INSERT' then
    perform public.create_user_notification(NEW.seller_id,'new_order','طلب شراء جديد','لديك طلب شراء جديد لأحد منتجاتك',
      jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':created');
  elsif NEW.status is distinct from OLD.status then
    if NEW.status='accepted' then
      perform public.create_user_notification(NEW.buyer_id,'order_accepted','تم قبول طلب الشراء',
        'وافق البائع على طلب الشراء. تم حجز المنتج لمدة 24 ساعة.',
        jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id,'hold_expires_at',NEW.hold_expires_at),
        'order:'||NEW.id::text||':accepted');
    elsif NEW.status='rejected' then
      perform public.create_user_notification(NEW.buyer_id,'order_rejected','تم رفض طلب الشراء','لم يوافق البائع على طلب الشراء',
        jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':rejected');
    elsif NEW.status='expired' then
      if OLD.status='accepted' then
        perform public.create_user_notification(NEW.buyer_id,'order_expired','انتهت مهلة حجز المنتج',
          'انتهت مهلة الحجز البالغة 24 ساعة وتم إتاحة المنتج من جديد.',
          jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':hold-expired:buyer');
        perform public.create_user_notification(NEW.seller_id,'order_expired','انتهت مهلة حجز المنتج',
          'انتهت مهلة الحجز وتمت إعادة إتاحة المخزون.',
          jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':hold-expired:seller');
      else
        perform public.create_user_notification(NEW.buyer_id,'order_expired','انتهت صلاحية طلب الشراء',
          'انتهت مهلة 48 ساعة دون رد من البائع',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),
          'order:'||NEW.id::text||':expired:buyer');
        perform public.create_user_notification(NEW.seller_id,'order_expired','انتهت صلاحية طلب شراء',
          'انتهت مهلة الرد على طلب الشراء',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),
          'order:'||NEW.id::text||':expired:seller');
      end if;
    elsif NEW.status='cancelled' then
      if auth.uid()=NEW.seller_id then
        perform public.create_user_notification(NEW.buyer_id,'order_updated','ألغى البائع طلب الشراء',
          'ألغى البائع الطلب لسبب متعلق بتوفر المنتج أو حالته.',
          jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id,'reason',NEW.cancellation_reason),
          'order:'||NEW.id::text||':seller-cancelled');
      else
        perform public.create_user_notification(NEW.seller_id,'order_updated','تحديث طلب الشراء','ألغى المشتري طلب الشراء',
          jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':cancelled');
      end if;
    elsif NEW.status='delivered' then
      perform public.create_user_notification(NEW.buyer_id,'order_delivered','أكد البائع تسليم المنتج',
        'يرجى فحص المنتج ثم تأكيد الاستلام لإتمام الطلب',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),
        'order:'||NEW.id::text||':delivered');
    elsif NEW.status='completed' then
      perform public.create_user_notification(NEW.seller_id,'order_completed','تم استلام المنتج',
        'أكد المشتري استلام المنتج وإتمام طلب الشراء',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),
        'order:'||NEW.id::text||':completed:seller');
    end if;
  end if;
  return NEW;
end;
$function$;
