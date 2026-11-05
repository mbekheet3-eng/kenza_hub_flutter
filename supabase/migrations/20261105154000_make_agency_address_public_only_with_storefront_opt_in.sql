drop policy if exists seller_shop_addresses_public_opt_in_read on public.seller_shop_addresses;
create policy seller_shop_addresses_public_opt_in_read
on public.seller_shop_addresses for select to anon, authenticated
using (
  exists (
    select 1 from public.seller_profiles sp
    where sp.id = seller_profile_id
      and sp.business_type = 'agency'
      and sp.is_active = true
      and sp.show_storefront = true
  )
);
grant select on public.seller_shop_addresses to anon;
create or replace function public.get_public_agency_shop_address(p_seller_profile_id uuid)
returns text
language sql
stable
security invoker
set search_path = ''
as $function$
  select a.address_line
  from public.seller_shop_addresses a
  join public.seller_profiles sp on sp.id = a.seller_profile_id
  where sp.id = p_seller_profile_id
    and sp.business_type = 'agency'
    and sp.is_active = true
    and sp.show_storefront = true
  limit 1;
$function$;
revoke all on function public.get_public_agency_shop_address(uuid) from public;
grant execute on function public.get_public_agency_shop_address(uuid) to anon, authenticated;
