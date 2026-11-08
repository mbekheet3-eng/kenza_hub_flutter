insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'seller-store-media',
  'seller-store-media',
  true,
  5242880,
  array['image/jpeg','image/png','image/webp']::text[]
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists seller_store_media_owner_insert on storage.objects;
create policy seller_store_media_owner_insert
on storage.objects for insert to authenticated
with check (
  bucket_id = 'seller-store-media'
  and exists (
    select 1
    from public.seller_profile_members m
    where m.seller_profile_id::text = (storage.foldername(name))[1]
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
);

drop policy if exists seller_store_media_owner_update on storage.objects;
create policy seller_store_media_owner_update
on storage.objects for update to authenticated
using (
  bucket_id = 'seller-store-media'
  and exists (
    select 1
    from public.seller_profile_members m
    where m.seller_profile_id::text = (storage.foldername(name))[1]
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
)
with check (
  bucket_id = 'seller-store-media'
  and exists (
    select 1
    from public.seller_profile_members m
    where m.seller_profile_id::text = (storage.foldername(name))[1]
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
);

drop policy if exists seller_store_media_owner_delete on storage.objects;
create policy seller_store_media_owner_delete
on storage.objects for delete to authenticated
using (
  bucket_id = 'seller-store-media'
  and exists (
    select 1
    from public.seller_profile_members m
    where m.seller_profile_id::text = (storage.foldername(name))[1]
      and m.user_id = (select auth.uid())
      and m.member_role = 'owner'
      and m.revoked_at is null
  )
);