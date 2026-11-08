drop policy if exists seller_shop_addresses_public_opt_in_read on public.seller_shop_addresses;
revoke select on public.seller_shop_addresses from anon;
drop function if exists public.get_public_agency_shop_address(uuid);

drop trigger if exists trg_ensure_agency_storefront_address on public.seller_profiles;
drop function if exists private.ensure_agency_storefront_address();

create or replace function private.sync_seller_shop_address_flag()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'DELETE' then
    update public.seller_profiles
       set has_shop_address = false
     where id = old.seller_profile_id;
    return old;
  end if;

  update public.seller_profiles
     set has_shop_address = true
   where id = new.seller_profile_id;
  return new;
end;
$function$;
revoke all on function private.sync_seller_shop_address_flag() from public, anon, authenticated;

comment on column public.seller_profiles.show_storefront is
  'Owner opt-in to display the physical shop-front image publicly; never controls disclosure of the private shop address.';
comment on table public.seller_shop_addresses is
  'Private owner-managed physical shop address. Never exposed through public API or directory views.';