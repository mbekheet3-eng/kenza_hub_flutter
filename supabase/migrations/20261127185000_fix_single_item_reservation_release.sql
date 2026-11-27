create or replace function public.guard_product_publication_with_moderation()
returns trigger language plpgsql security definer set search_path to 'public','pg_temp'
as $function$
declare moderation_approved boolean := false; listing_content_changed boolean := false;
begin
  if tg_op='UPDATE' then
    listing_content_changed:=new.title is distinct from old.title or new.description is distinct from old.description or new.category_id is distinct from old.category_id;
    if listing_content_changed then
      if old.status='published' then new.status:='draft'; end if;
      insert into public.product_moderation(product_id,owner_id,status,result,reviewed_at,updated_at)
      values(new.id,new.owner_id,'pending',null,null,now())
      on conflict(product_id) do update set owner_id=excluded.owner_id,status='pending',result=null,reviewed_at=null,updated_at=now();
    end if;
    if new.status='published' and old.status='archived' and old.reserved_by_order_id is not null and new.reserved_by_order_id is null then return new; end if;
  end if;
  if new.status='published' then
    select exists(select 1 from public.product_moderation pm where pm.product_id=new.id and pm.status='approved') into moderation_approved;
    if not moderation_approved then raise exception 'Product images must pass server-side moderation before publication' using errcode='42501'; end if;
  end if;
  return new;
end;
$function$;

create or replace function public.validate_product_order_insert()
returns trigger language plpgsql set search_path to ''
as $function$
declare v_owner_id uuid; v_price numeric; v_currency text; v_product_status text; v_has_variants boolean; v_available integer;
  v_variant_color text; v_variant_size text; v_reserved_by_order_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(new.product_id::text||':'||auth.uid()::text,0));
  if exists(select 1 from public.product_orders o where o.product_id=new.product_id and o.buyer_id=auth.uid() and o.status in ('pending','accepted','delivered')) then
    raise exception 'An active purchase request already exists for this product' using errcode='23505';
  end if;
  select p.owner_id,p.price,p.currency,p.status,p.has_variants,p.reserved_by_order_id
  into v_owner_id,v_price,v_currency,v_product_status,v_has_variants,v_reserved_by_order_id
  from public.products p where p.id=new.product_id for update;
  if not found or v_product_status<>'published' then raise exception 'Product is not available for purchase' using errcode='23514'; end if;
  if v_owner_id=auth.uid() then raise exception 'You cannot purchase your own product' using errcode='23514'; end if;
  if v_price<=0 then raise exception 'Product price must be greater than zero' using errcode='23514'; end if;
  if not v_has_variants and v_reserved_by_order_id is not null then raise exception 'out_of_stock' using errcode='23514'; end if;
  if v_has_variants then
    if new.variant_id is null or new.quantity<1 then raise exception 'Choose a product variant and quantity' using errcode='23514'; end if;
    select v.quantity,v.color,v.size into v_available,v_variant_color,v_variant_size from public.product_variants v where v.id=new.variant_id and v.product_id=new.product_id;
    if not found or new.quantity>v_available then raise exception 'out_of_stock' using errcode='23514'; end if;
    new.variant_color:=v_variant_color; new.variant_size:=v_variant_size;
  else
    if new.variant_id is not null or new.quantity<>1 then raise exception 'Single-unit listings can only be requested one at a time' using errcode='23514'; end if;
    new.variant_color:=null; new.variant_size:=null;
  end if;
  new.buyer_id:=auth.uid(); new.seller_id:=v_owner_id; new.agreed_price:=v_price*new.quantity; new.currency:=v_currency;
  new.status:='pending'; new.created_at:=now(); new.updated_at:=now(); new.expires_at:=now()+interval '48 hours'; new.reminder_sent_at:=null;
  return new;
end;
$function$;

create or replace function public.validate_product_order_status_transition()
returns trigger language plpgsql security definer set search_path to ''
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
        update public.product_variants set quantity=quantity-new.quantity where id=new.variant_id and product_id=new.product_id and quantity>=new.quantity;
        get diagnostics v_rows=row_count; if v_rows=0 then raise exception 'out_of_stock' using errcode='23514'; end if;
      else
        update public.products set reserved_by_order_id=new.id where id=new.product_id and owner_id=new.seller_id and status='published' and reserved_by_order_id is null;
        get diagnostics v_rows=row_count; if v_rows=0 then raise exception 'out_of_stock' using errcode='23514'; end if;
      end if;
      new.hold_expires_at:=now()+interval '24 hours'; new.postponement_requested_at:=null; new.postponement_requested_until:=null;
      new.postponement_extension_count:=0; new.stock_restored_at:=null; new.cancellation_reason:=null; new.cancellation_note:=null;
    elsif old.status='accepted' and new.status in ('cancelled','expired') then
      if old.stock_restored_at is null then
        if old.variant_id is not null then update public.product_variants set quantity=quantity+old.quantity where id=old.variant_id and product_id=old.product_id;
        else update public.products set status='published',reserved_by_order_id=null where id=old.product_id and reserved_by_order_id=old.id;
        end if;
        new.stock_restored_at:=now();
      end if;
      new.postponement_requested_at:=null; new.postponement_requested_until:=null;
    elsif old.status='accepted' and new.status='delivered' then
      if old.variant_id is null then update public.products set status='archived',reserved_by_order_id=null where id=old.product_id and reserved_by_order_id=old.id; end if;
      new.postponement_requested_at:=null; new.postponement_requested_until:=null;
    end if;
  end if;
  new.updated_at:=now(); return new;
end;
$function$;
revoke update(reserved_by_order_id) on public.products from authenticated;

create or replace function public.notify_order_activity()
returns trigger language plpgsql security definer set search_path to ''
as $function$
begin
  if TG_OP='INSERT' then
    perform public.create_user_notification(NEW.seller_id,'new_order','طلب شراء جديد','لديك طلب شراء جديد لأحد منتجاتك',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':created');
  elsif NEW.status is distinct from OLD.status then
    if NEW.status='accepted' then
      perform public.create_user_notification(NEW.buyer_id,'order_accepted','تم قبول طلب الشراء','وافق البائع على طلب الشراء. تم حجز المنتج لمدة 24 ساعة.',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id,'hold_expires_at',NEW.hold_expires_at),'order:'||NEW.id::text||':accepted');
    elsif NEW.status='rejected' then
      perform public.create_user_notification(NEW.buyer_id,'order_rejected','تم رفض طلب الشراء','لم يوافق البائع على طلب الشراء',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':rejected');
    elsif NEW.status='expired' then
      if OLD.status='accepted' then
        perform public.create_user_notification(NEW.buyer_id,'order_expired','انتهت مهلة حجز المنتج','انتهت مهلة الحجز البالغة 24 ساعة وتم إتاحة المنتج من جديد.',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':hold-expired:buyer');
        perform public.create_user_notification(NEW.seller_id,'order_expired','انتهت مهلة حجز المنتج','انتهت مهلة الحجز وتمت إعادة إتاحة المخزون.',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':hold-expired:seller');
      else
        perform public.create_user_notification(NEW.buyer_id,'order_expired','انتهت صلاحية طلب الشراء','انتهت مهلة 48 ساعة دون رد من البائع',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':expired:buyer');
        perform public.create_user_notification(NEW.seller_id,'order_expired','انتهت صلاحية طلب شراء','انتهت مهلة الرد على طلب الشراء',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':expired:seller');
      end if;
    elsif NEW.status='cancelled' then
      if auth.uid()=NEW.seller_id then
        perform public.create_user_notification(NEW.buyer_id,'order_updated','ألغى البائع طلب الشراء','ألغى البائع الطلب لسبب متعلق بتوفر المنتج أو حالته.',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id,'reason',NEW.cancellation_reason),'order:'||NEW.id::text||':seller-cancelled');
      else
        perform public.create_user_notification(NEW.seller_id,'order_updated','تحديث طلب الشراء','ألغى المشتري طلب الشراء',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':cancelled');
      end if;
    elsif NEW.status='delivered' then
      perform public.create_user_notification(NEW.buyer_id,'order_delivered','أكد البائع تسليم المنتج','يرجى فحص المنتج ثم تأكيد الاستلام لإتمام الطلب',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':delivered');
    elsif NEW.status='completed' then
      perform public.create_user_notification(NEW.seller_id,'order_completed','تم استلام المنتج','أكد المشتري استلام المنتج وإتمام طلب الشراء',jsonb_build_object('order_id',NEW.id,'product_id',NEW.product_id),'order:'||NEW.id::text||':completed:seller');
    end if;
  end if;
  return NEW;
end;
$function$;