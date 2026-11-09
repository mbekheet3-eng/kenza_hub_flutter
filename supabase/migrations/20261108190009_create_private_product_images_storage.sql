insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'product-images',
  'product-images',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists product_images_select_published_or_owner on storage.objects;
create policy product_images_select_published_or_owner
on storage.objects for select
to anon, authenticated
using (
  bucket_id = 'product-images'
  and (
    (
      (storage.foldername(name))[1] = (select auth.uid()::text)
      and (select auth.uid()) is not null
    )
    or exists (
      select 1
      from public.product_images pi
      join public.products p on p.id = pi.product_id
      where pi.storage_path = objects.name
        and p.status = 'published'
    )
  )
);

drop policy if exists product_images_insert_own_product on storage.objects;
create policy product_images_insert_own_product
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'product-images'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
  and exists (
    select 1
    from public.products p
    where p.id::text = (storage.foldername(objects.name))[2]
      and p.owner_id = (select auth.uid())
  )
);

drop policy if exists product_images_update_own_product on storage.objects;
create policy product_images_update_own_product
on storage.objects for update
to authenticated
using (
  bucket_id = 'product-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'product-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
  and exists (
    select 1
    from public.products p
    where p.id::text = (storage.foldername(objects.name))[2]
      and p.owner_id = (select auth.uid())
  )
);

drop policy if exists product_images_delete_own_product on storage.objects;
create policy product_images_delete_own_product
on storage.objects for delete
to authenticated
using (
  bucket_id = 'product-images'
  and owner_id = (select auth.uid()::text)
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
