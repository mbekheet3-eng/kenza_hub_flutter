create or replace function public.validate_product_order_status_transition()
returns trigger
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_owner_id uuid;
  v_price numeric;
  v_currency text;
  v_product_status text;
  v_has_variants boolean;
  v_rows integer;
begin
  if new.status is distinct from old.status then
    if not (
      (old.status = 'pending' and new.status in ('accepted', 'rejected', 'cancelled', 'expired'))
      or (old.status = 'accepted' and new.status in ('cancelled', 'expired', 'delivered'))
      or (old.status = 'delivered' and new.status = 'completed')
    ) then
      raise exception 'Invalid purchase-order status transition: % -> %', old.status, new.status using errcode = '23514';
    end if;
    if new.status = 'accepted' then
      select p.owner_id, p.price, p.currency, p.status, p.has_variants
      into v_owner_id, v_price, v_currency, v_product_status, v_has_variants
      from public.products p where p.id = new.product_id for update;
      if not found or v_product_status <> 'published' or v_owner_id <> new.seller_id
        or v_price * new.quantity <> new.agreed_price or v_currency <> new.currency
        or v_has_variants <> (new.variant_id is not null) then
        raise exception 'The product price or availability changed; refresh the listing before accepting' using errcode = '23514';
      end if;
      if new.variant_id is not null then
        update public.product_variants set quantity = quantity - new.quantity
        where id = new.variant_id and product_id = new.product_id and quantity >= new.quantity;
        get diagnostics v_rows = row_count;
        if v_rows = 0 then raise exception 'out_of_stock' using errcode = '23514'; end if;
      else
        update public.products set status = 'archived', reserved_by_order_id = new.id
        where id = new.product_id and owner_id = new.seller_id and status = 'published' and reserved_by_order_id is null;
        get diagnostics v_rows = row_count;
        if v_rows = 0 then raise exception 'out_of_stock' using errcode = '23514'; end if;
      end if;
      new.hold_expires_at := now() + interval '24 hours';
      new.postponement_requested_at := null;
      new.postponement_requested_until := null;
      new.postponement_extension_count := 0;
      new.stock_restored_at := null;
      new.cancellation_reason := null;
      new.cancellation_note := null;
    elsif old.status = 'accepted' and new.status in ('cancelled', 'expired') then
      if old.stock_restored_at is null then
        if old.variant_id is not null then
          update public.product_variants set quantity = quantity + old.quantity
          where id = old.variant_id and product_id = old.product_id;
        else
          update public.products set status = 'published', reserved_by_order_id = null
          where id = old.product_id and reserved_by_order_id = old.id;
        end if;
        new.stock_restored_at := now();
      end if;
      new.postponement_requested_at := null;
      new.postponement_requested_until := null;
    elsif old.status = 'accepted' and new.status = 'delivered' then
      if old.variant_id is null then
        update public.products set status = 'archived', reserved_by_order_id = null
        where id = old.product_id and reserved_by_order_id = old.id;
      end if;
      new.postponement_requested_at := null;
      new.postponement_requested_until := null;
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$function$;