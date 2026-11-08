create or replace function private.edit_product(
  p_product_id uuid,
  p_category_id uuid,
  p_title_ar text,
  p_title_en text,
  p_description_ar text,
  p_description_en text,
  p_price numeric,
  p_condition_id uuid,
  p_color_id uuid,
  p_size_id uuid,
  p_brand_name text,
  p_weight_kg numeric,
  p_audience text
)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_seller uuid;
  v_pending uuid;
  v_old_audience text;
  v_audience text := coalesce(p_audience, 'public');
begin
  select seller_id, audience into v_seller, v_old_audience
  from public.products where id = p_product_id for update;

  if v_seller is null then raise exception 'PRODUCT_NOT_FOUND'; end if;
  if not private.has_seller_permission(v_seller, 'products:update') then
    raise exception 'PRODUCT_UPDATE_PERMISSION_REQUIRED';
  end if;

  -- Kenza delivery coverage is optional; editing must not depend on it.
  if p_title_ar is null
     or pg_catalog.char_length(pg_catalog.btrim(p_title_ar)) not between 3 and 140 then
    raise exception 'INVALID_PRODUCT_TITLE';
  end if;
  if not exists (select 1 from public.categories where id = p_category_id and is_active) then
    raise exception 'INVALID_CATEGORY';
  end if;
  if not exists (select 1 from public.product_conditions where id = p_condition_id and is_active) then
    raise exception 'INVALID_PRODUCT_CONDITION';
  end if;
  if p_color_id is not null and not exists (select 1 from public.product_colors where id = p_color_id and is_active) then
    raise exception 'INVALID_PRODUCT_COLOR';
  end if;
  if p_size_id is not null and not exists (select 1 from public.product_sizes where id = p_size_id and is_active) then
    raise exception 'INVALID_PRODUCT_SIZE';
  end if;
  if p_price is null or p_price <= 0 then raise exception 'INVALID_PRICE'; end if;
  if p_weight_kg is not null and (p_weight_kg <= 0 or p_weight_kg > 10) then
    raise exception 'WEIGHT_LIMIT_EXCEEDED';
  end if;
  if v_audience not in ('public', 'followers', 'private') then raise exception 'INVALID_AUDIENCE'; end if;

  if v_old_audience = 'public' and v_audience <> 'public'
     and exists (select 1 from public.product_images
                 where product_id = p_product_id and storage_bucket = 'product-images') then
    raise exception 'AUDIENCE_CHANGE_REQUIRES_MEDIA_MIGRATION';
  end if;

  select id into v_pending from public.product_statuses
  where slug = 'pending_review' and is_active;
  if v_pending is null then raise exception 'REFERENCE_DATA_NOT_READY'; end if;

  update public.products
  set category_id = p_category_id,
      title_ar = pg_catalog.btrim(p_title_ar),
      title_en = nullif(pg_catalog.btrim(p_title_en), ''),
      description_ar = p_description_ar,
      description_en = p_description_en,
      price = p_price,
      condition_id = p_condition_id,
      color_id = p_color_id,
      size_id = p_size_id,
      brand_name = nullif(pg_catalog.btrim(p_brand_name), ''),
      weight_kg = p_weight_kg,
      audience = v_audience,
      moderation_status = 'pending',
      status_id = v_pending,
      published_at = null
  where id = p_product_id;
end;
$function$;
