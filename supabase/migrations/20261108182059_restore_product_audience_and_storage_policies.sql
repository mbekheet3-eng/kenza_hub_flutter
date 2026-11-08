drop policy if exists temp_product_read_all on public.products;
drop policy if exists temp_product_images_read_all on public.product_images;
drop policy if exists temp_product_image_storage_read on storage.objects;
drop policy if exists temp_product_image_storage_insert on storage.objects;
drop policy if exists temp_product_image_storage_update on storage.objects;
drop policy if exists temp_product_image_storage_delete on storage.objects;
