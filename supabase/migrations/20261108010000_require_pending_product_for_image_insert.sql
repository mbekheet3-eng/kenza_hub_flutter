-- Prevent adding new image metadata to an already published, rejected, or hidden product.
-- The seller must first edit the product, which returns it to pending_review.
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
  v_product public.products%rowtype;
  v_pending uuid;
  v_bucket text;
  v_expected_path text;
  v_id uuid;
begin
  if not private.is_active_user() then
    raise exception 'AUTH_REQUIRED';
  end if;

  select *
    into v_product
    from public.products
   where id = p_product_id
   for update;

  if not found then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  if not private.can_manage_product_image(p_product_id) then
    raise exception 'PRODUCT_IMAGE_PERMISSION_REQUIRED';
  end if;

  select id
    into v_pending
    from public.product_statuses
   where slug = 'pending_review'
     and is_active;

  if v_pending is null then
    raise exception 'PENDING_REVIEW_STATUS_NOT_CONFIGURED';
  end if;

  if v_product.moderation_status is distinct from 'pending'
     or v_product.status_id is distinct from v_pending then
    raise exception 'PRODUCT_NOT_PENDING_REVIEW';
  end if;

  v_bucket := case
    when v_product.audience = 'public' then 'product-images'
    when v_product.audience in ('followers', 'private') then 'restricted-product-images'
    else null
  end;

  if v_bucket is null then
    raise exception 'INVALID_PRODUCT_AUDIENCE';
  end if;

  v_expected_path := 'products/' || p_product_id::text || '/' || auth.uid()::text || '/';

  if p_image_path is null
     or p_image_path not like v_expected_path || '%'
     or position('..' in p_image_path) > 0
     or array_length(string_to_array(p_image_path, '/'), 1) <> 4 then
    raise exception 'INVALID_IMAGE_PATH';
  end if;

  if not exists (
    select 1
      from storage.objects
     where bucket_id = v_bucket
       and name = p_image_path
  ) then
    raise exception 'IMAGE_OBJECT_NOT_FOUND';
  end if;

  insert into public.product_images(
    product_id,
    image_path,
    storage_bucket,
    display_order
  )
  values (
    p_product_id,
    p_image_path,
    v_bucket,
    p_display_order
  )
  returning id into v_id;

  return v_id;
end;
$$;
