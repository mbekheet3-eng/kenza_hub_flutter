-- Guard INSERT separately from UPDATE: OLD is not defined on INSERT triggers.
create or replace function public.guard_product_variant_mode()
returns trigger language plpgsql set search_path=''
as $$
begin
  if new.has_variants then
    if not exists (select 1 from public.account_roles r where r.user_id=new.owner_id and r.role='pro_seller' and r.is_active) then
      raise exception 'Only active Pro Sellers can manage product variants' using errcode='42501';
    end if;
  elsif tg_op='UPDATE' and old.has_variants and exists (select 1 from public.product_orders o where o.product_id=old.id and o.variant_id is not null) then
    raise exception 'Cannot remove variants while purchase history references this inventory' using errcode='23514';
  end if;
  return new;
end;
$$;
