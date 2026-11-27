-- Prevent switching between single-unit and variant inventory after any order exists.
create or replace function public.guard_product_variant_mode()
returns trigger language plpgsql set search_path=''
as $$
begin
  if new.has_variants and not exists (select 1 from public.account_roles r where r.user_id=new.owner_id and r.role='pro_seller' and r.is_active) then
    raise exception 'Only active Pro Sellers can manage product variants' using errcode='42501';
  end if;
  if tg_op='UPDATE' and new.has_variants is distinct from old.has_variants
     and exists (select 1 from public.product_orders o where o.product_id=old.id) then
    raise exception 'Cannot change single-unit/variant mode while order history exists' using errcode='23514';
  end if;
  return new;
end;
$$;
