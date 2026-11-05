drop policy if exists seller_store_media_owner_select on public.seller_store_media;
create policy seller_store_media_owner_select on public.seller_store_media
for select to authenticated using (
  exists (
    select 1 from public.seller_profile_members m
    where m.seller_profile_id = seller_store_media.seller_profile_id
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
);

drop policy if exists seller_store_media_owner_insert on public.seller_store_media;
create policy seller_store_media_owner_insert on public.seller_store_media
for insert to authenticated with check (
  exists (
    select 1 from public.seller_profile_members m
    where m.seller_profile_id = seller_store_media.seller_profile_id
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
);

drop policy if exists seller_store_media_owner_update on public.seller_store_media;
create policy seller_store_media_owner_update on public.seller_store_media
for update to authenticated using (
  exists (
    select 1 from public.seller_profile_members m
    where m.seller_profile_id = seller_store_media.seller_profile_id
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
) with check (
  exists (
    select 1 from public.seller_profile_members m
    where m.seller_profile_id = seller_store_media.seller_profile_id
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
);

drop policy if exists seller_store_media_owner_delete on public.seller_store_media;
create policy seller_store_media_owner_delete on public.seller_store_media
for delete to authenticated using (
  exists (
    select 1 from public.seller_profile_members m
    where m.seller_profile_id = seller_store_media.seller_profile_id
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
);
