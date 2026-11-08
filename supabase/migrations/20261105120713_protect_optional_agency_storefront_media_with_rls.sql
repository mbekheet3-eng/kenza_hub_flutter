create table if not exists public.seller_store_media (
  seller_profile_id uuid primary key references public.seller_profiles(id) on delete cascade,
  cover_image_url text check (cover_image_url is null or char_length(cover_image_url) <= 2048),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.seller_store_media enable row level security;

drop policy if exists seller_store_media_owner_select on public.seller_store_media;
create policy seller_store_media_owner_select on public.seller_store_media
for select to authenticated using (
  exists (select 1 from public.seller_profile_members m
          where m.seller_profile_id = seller_profile_id
            and m.user_id = (select auth.uid())
            and m.member_role = 'owner' and m.revoked_at is null)
);

drop policy if exists seller_store_media_public_opt_in_read on public.seller_store_media;
create policy seller_store_media_public_opt_in_read on public.seller_store_media
for select to anon, authenticated using (
  exists (select 1 from public.seller_profiles sp
          where sp.id = seller_profile_id and sp.is_active = true
            and (sp.business_type = 'online_store'
              or (sp.business_type = 'agency' and sp.show_storefront = true)))
);

drop policy if exists seller_store_media_owner_insert on public.seller_store_media;
create policy seller_store_media_owner_insert on public.seller_store_media
for insert to authenticated with check (
  exists (select 1 from public.seller_profile_members m
          where m.seller_profile_id = seller_profile_id
            and m.user_id = (select auth.uid())
            and m.member_role = 'owner' and m.revoked_at is null)
);

drop policy if exists seller_store_media_owner_update on public.seller_store_media;
create policy seller_store_media_owner_update on public.seller_store_media
for update to authenticated using (
  exists (select 1 from public.seller_profile_members m
          where m.seller_profile_id = seller_profile_id
            and m.user_id = (select auth.uid())
            and m.member_role = 'owner' and m.revoked_at is null)
) with check (
  exists (select 1 from public.seller_profile_members m
          where m.seller_profile_id = seller_profile_id
            and m.user_id = (select auth.uid())
            and m.member_role = 'owner' and m.revoked_at is null)
);

drop policy if exists seller_store_media_owner_delete on public.seller_store_media;
create policy seller_store_media_owner_delete on public.seller_store_media
for delete to authenticated using (
  exists (select 1 from public.seller_profile_members m
          where m.seller_profile_id = seller_profile_id
            and m.user_id = (select auth.uid())
            and m.member_role = 'owner' and m.revoked_at is null)
);

revoke all on public.seller_store_media from anon, authenticated;
grant select on public.seller_store_media to anon, authenticated;
grant insert, update, delete on public.seller_store_media to authenticated;
grant all on public.seller_store_media to service_role;

revoke select (cover_image_url) on public.seller_profiles from anon, authenticated;
revoke update (cover_image_url) on public.seller_profiles from authenticated;

create or replace view public.agency_directory with (security_invoker = true) as
select sp.id, sp.display_name, sp.business_name, sp.bio, sp.avatar_url,
       sp.verification_status, sp.created_at, sp.shop_area,
       sp.show_storefront, sm.cover_image_url, sp.social_links
from public.seller_profiles sp
left join public.seller_store_media sm on sm.seller_profile_id = sp.id
where sp.is_active and sp.business_type = 'agency' and sp.has_shop_address = true;

create or replace view public.online_store_directory with (security_invoker = true) as
select sp.id, sp.display_name, sp.business_name, sp.bio, sp.avatar_url,
       sp.verification_status, sp.created_at, sm.cover_image_url, sp.social_links
from public.seller_profiles sp
left join public.seller_store_media sm on sm.seller_profile_id = sp.id
where sp.is_active and sp.business_type = 'online_store';
