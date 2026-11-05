alter table public.seller_profiles
  add column if not exists has_shop_address boolean not null default false;

create or replace function private.sync_seller_shop_address_flag()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'DELETE' then
    if exists (
      select 1 from public.seller_profiles sp
      where sp.id = old.seller_profile_id and sp.show_storefront = true
    ) then
      raise exception 'DISABLE_STOREFRONT_BEFORE_REMOVING_ADDRESS';
    end if;
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

drop trigger if exists trg_sync_seller_shop_address_flag on public.seller_shop_addresses;
create trigger trg_sync_seller_shop_address_flag
after insert or update or delete on public.seller_shop_addresses
for each row execute function private.sync_seller_shop_address_flag();

update public.seller_profiles sp
set has_shop_address = exists (
  select 1 from public.seller_shop_addresses a
  where a.seller_profile_id = sp.id
);

grant select (has_shop_address) on public.seller_profiles to anon, authenticated;

create or replace view public.agency_directory with (security_invoker = true) as
select id, display_name, business_name, bio, avatar_url, verification_status,
       created_at, shop_area, show_storefront, cover_image_url, social_links
from public.seller_profiles
where is_active
  and business_type = 'agency'
  and has_shop_address = true;
