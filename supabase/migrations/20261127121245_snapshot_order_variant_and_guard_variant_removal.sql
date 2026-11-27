-- Preserve selected variant details on each order and prevent disabling inventory with order history.
alter table public.product_orders add column if not exists variant_color text, add column if not exists variant_size text;
create or replace function public.guard_product_variant_mode() returns trigger language plpgsql set search_path='' as $$ begin
 if new.has_variants and not exists(select 1 from public.account_roles r where r.user_id=new.owner_id and r.role='pro_seller' and r.is_active) then raise exception 'Only active Pro Sellers can manage product variants' using errcode='42501'; end if;
 if not new.has_variants and old.has_variants and exists(select 1 from public.product_orders o where o.product_id=old.id and o.variant_id is not null) then raise exception 'Cannot remove variants while purchase history references this inventory' using errcode='23514'; end if;
 return new; end; $$;
create or replace function public.validate_product_order_insert() returns trigger language plpgsql set search_path='' as $$
declare v_owner_id uuid; v_price numeric; v_currency text; v_product_status text; v_has_variants boolean; v_available integer; v_variant_color text; v_variant_size text;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(new.product_id::text||':'||auth.uid()::text,0));
 if exists(select 1 from public.product_orders o where o.product_id=new.product_id and o.buyer_id=auth.uid() and o.status in ('pending','accepted','delivered')) then raise exception 'An active purchase request already exists for this product' using errcode='23505'; end if;
 select p.owner_id,p.price,p.currency,p.status,p.has_variants into v_owner_id,v_price,v_currency,v_product_status,v_has_variants from public.products p where p.id=new.product_id;
 if not found or v_product_status<>'published' then raise exception 'Product is not available for purchase' using errcode='23514'; end if;
 if v_owner_id=auth.uid() then raise exception 'You cannot purchase your own product' using errcode='23514'; end if;
 if v_price<=0 then raise exception 'Product price must be greater than zero' using errcode='23514'; end if;
 if v_has_variants then
  if new.variant_id is null or new.quantity<1 then raise exception 'Choose a product variant and quantity' using errcode='23514'; end if;
  select v.quantity,v.color,v.size into v_available,v_variant_color,v_variant_size from public.product_variants v where v.id=new.variant_id and v.product_id=new.product_id;
  if not found or new.quantity>v_available then raise exception 'out_of_stock' using errcode='23514'; end if;
  new.variant_color:=v_variant_color; new.variant_size:=v_variant_size;
 else
  if new.variant_id is not null or new.quantity<>1 then raise exception 'Single-unit listings can only be requested one at a time' using errcode='23514'; end if;
  new.variant_color:=null; new.variant_size:=null;
 end if;
 new.buyer_id:=auth.uid(); new.seller_id:=v_owner_id; new.agreed_price:=v_price*new.quantity; new.currency:=v_currency; new.status:='pending'; new.created_at:=now(); new.updated_at:=now(); new.expires_at:=now()+interval '48 hours'; new.reminder_sent_at:=null; return new;
end; $$;
