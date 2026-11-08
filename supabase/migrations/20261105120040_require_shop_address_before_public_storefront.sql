create or replace function private.ensure_agency_storefront_address()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.show_storefront = true
     and not exists (
       select 1 from public.seller_shop_addresses a
       where a.seller_profile_id = new.id
     ) then
    raise exception 'AGENCY_SHOP_ADDRESS_REQUIRED_FOR_STOREFRONT';
  end if;
  return new;
end;
$function$;
revoke all on function private.ensure_agency_storefront_address() from public, anon, authenticated;

drop trigger if exists trg_ensure_agency_storefront_address on public.seller_profiles;
create trigger trg_ensure_agency_storefront_address
before insert or update of show_storefront on public.seller_profiles
for each row execute function private.ensure_agency_storefront_address();
