-- Agency Corner and Online Stores public profile fields.
-- Full physical shop address is owner-only and disclosed publicly only after opt-in.

create or replace function private.valid_seller_social_links(p_links jsonb)
returns boolean
language sql
immutable
set search_path = ''
as $function$
  select coalesce(
    jsonb_typeof(p_links) = 'object'
    and not exists (
      select 1
      from jsonb_each(p_links) as link(key, value)
      where link.key not in ('facebook', 'instagram', 'website', 'whatsapp')
         or jsonb_typeof(link.value) <> 'string'
         or link.value::text not like '"https://%'
         or char_length(link.value #>> '{}') > 2048
    ),
    false
  );
$function$;
revoke all on function private.valid_seller_social_links(jsonb) from public, anon, authenticated;

alter table public.seller_profiles
  add column if not exists shop_area text,
  add column if not exists show_storefront boolean not null default false,
  add column if not exists cover_image_url text,
  add column if not exists social_links jsonb not null default '{}'::jsonb;

alter table public.seller_profiles
  add constraint seller_profiles_shop_area_length
    check (shop_area is null or char_length(btrim(shop_area)) between 2 and 120),
  add constraint seller_profiles_cover_image_url_length
    check (cover_image_url is null or char_length(cover_image_url) <= 2048),
  add constraint seller_profiles_social_links_valid
    check (private.valid_seller_social_links(social_links)),
  add constraint seller_profiles_agency_storefront_only
    check (show_storefront = false or business_type = 'agency'),
  add constraint seller_profiles_agency_area_only
    check (shop_area is null or business_type = 'agency');

create table if not exists public.seller_shop_addresses (
  seller_profile_id uuid primary key references public.seller_profiles(id) on delete cascade,
  address_line text not null check (char_length(btrim(address_line)) between 5 and 300),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.seller_shop_addresses enable row level security;

drop policy if exists seller_shop_addresses_owner_select on public.seller_shop_addresses;
create policy seller_shop_addresses_owner_select on public.seller_shop_addresses
for select to authenticated using (
  exists (select 1 from public.seller_profiles sp
          where sp.id = seller_profile_id and sp.owner_user_id = (select auth.uid()))
);

drop policy if exists seller_shop_addresses_owner_insert on public.seller_shop_addresses;
create policy seller_shop_addresses_owner_insert on public.seller_shop_addresses
for insert to authenticated with check (
  exists (select 1 from public.seller_profiles sp
          where sp.id = seller_profile_id and sp.owner_user_id = (select auth.uid())
            and sp.business_type = 'agency')
);

drop policy if exists seller_shop_addresses_owner_update on public.seller_shop_addresses;
create policy seller_shop_addresses_owner_update on public.seller_shop_addresses
for update to authenticated using (
  exists (select 1 from public.seller_profiles sp
          where sp.id = seller_profile_id and sp.owner_user_id = (select auth.uid())
            and sp.business_type = 'agency')
) with check (
  exists (select 1 from public.seller_profiles sp
          where sp.id = seller_profile_id and sp.owner_user_id = (select auth.uid())
            and sp.business_type = 'agency')
);

drop policy if exists seller_shop_addresses_owner_delete on public.seller_shop_addresses;
create policy seller_shop_addresses_owner_delete on public.seller_shop_addresses
for delete to authenticated using (
  exists (select 1 from public.seller_profiles sp
          where sp.id = seller_profile_id and sp.owner_user_id = (select auth.uid())
            and sp.business_type = 'agency')
);

revoke all on public.seller_shop_addresses from anon, authenticated;
grant select, insert, update, delete on public.seller_shop_addresses to authenticated;
grant all on public.seller_shop_addresses to service_role;

create or replace function public.get_public_agency_shop_address(p_seller_profile_id uuid)
returns text language sql stable security definer set search_path = ''
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

create or replace view public.agency_directory with (security_invoker = true) as
select id, display_name, business_name, bio, avatar_url, verification_status,
       created_at, shop_area, show_storefront, cover_image_url, social_links
from public.seller_profiles where is_active and business_type = 'agency';

create or replace view public.online_store_directory with (security_invoker = true) as
select id, display_name, business_name, bio, avatar_url, verification_status,
       created_at, cover_image_url, social_links
from public.seller_profiles where is_active and business_type = 'online_store';

grant select (shop_area, show_storefront, cover_image_url, social_links)
  on public.seller_profiles to anon, authenticated;
grant update (shop_area, show_storefront, cover_image_url, social_links)
  on public.seller_profiles to authenticated;
grant select on public.agency_directory, public.online_store_directory to anon, authenticated;

comment on column public.seller_profiles.shop_area is
  'Public area/neighborhood for a physical Agency Corner shop; not a personal address.';
comment on column public.seller_profiles.show_storefront is
  'Owner opt-in to show the physical shop address and storefront details publicly.';
comment on column public.seller_profiles.cover_image_url is
  'Optional public cover image for Agency Corner or Online Store profile.';
comment on column public.seller_profiles.social_links is
  'Optional public HTTPS links: facebook, instagram, website, whatsapp.';
comment on table public.seller_shop_addresses is
  'Private owner-managed physical shop address; public disclosure requires show_storefront=true via RPC.';
