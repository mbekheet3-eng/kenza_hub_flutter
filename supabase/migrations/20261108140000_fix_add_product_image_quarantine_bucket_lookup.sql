create or replace function private.add_product_image(
  p_product_id uuid,
  p_image_path text,
  p_display_order integer
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_id uuid;
  v_audience text;
  v_bucket text;
  v_expected_path text;
begin
  if not private.is_active_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  if not private.can_manage_product_image(p_product_id) then
    raise exception 'PRODUCT_IMAGE_PERMISSION_REQUIRED';
  end if;

  select audience into v_audience
  from public.products
  where id=p_product_id;

  v_expected_path := 'products/' || p_product_id::text || '/' || auth.uid()::text || '/';
  if p_image_path not like v_expected_path || '%'
     or position('..' in p_image_path) > 0
     or array_length(string_to_array(p_image_path,'/'),1) <> 4 then
    raise exception 'INVALID_IMAGE_PATH';
  end if;

  -- New uploads are stored in the private quarantine bucket before moderation.
  -- Keep compatibility with legacy public objects that may already exist.
  if exists (
    select 1 from storage.objects
    where bucket_id='restricted-product-images' and name=p_image_path
  ) then
    v_bucket := 'restricted-product-images';
  elsif v_audience='public' and exists (
    select 1 from storage.objects
    where bucket_id='product-images' and name=p_image_path
  ) then
    v_bucket := 'product-images';
  else
    raise exception 'IMAGE_OBJECT_NOT_FOUND';
  end if;

  insert into public.product_images(product_id,image_path,storage_bucket,display_order)
  values(p_product_id,p_image_path,v_bucket,p_display_order)
  returning id into v_id;

  return v_id;
end
$$;

revoke all on function private.add_product_image(uuid,text,integer) from public,anon;
grant execute on function private.add_product_image(uuid,text,integer) to authenticated;
