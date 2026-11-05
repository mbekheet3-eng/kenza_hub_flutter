-- Validate product title and active reference data before creating a listing.
-- Align optional weight validation with products_weight_max_10kg_check.

CREATE OR REPLACE FUNCTION private.create_product(
  p_seller_profile_id uuid,
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
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_currency uuid;
  v_status uuid;
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL OR NOT private.is_active_user() THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT private.is_current_user_phone_verified() THEN
    RAISE EXCEPTION 'PHONE_VERIFICATION_REQUIRED';
  END IF;

  IF NOT private.has_seller_permission(p_seller_profile_id, 'products:create') THEN
    RAISE EXCEPTION 'PRODUCT_CREATE_PERMISSION_REQUIRED';
  END IF;

  IF NOT private.is_seller_in_service_area(p_seller_profile_id) THEN
    RAISE EXCEPTION 'OUTSIDE_DELIVERY_COVERAGE';
  END IF;

  IF p_title_ar IS NULL OR char_length(trim(p_title_ar)) NOT BETWEEN 3 AND 140 THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_TITLE';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.categories
    WHERE id = p_category_id AND is_active
  ) THEN
    RAISE EXCEPTION 'INVALID_CATEGORY';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.product_conditions
    WHERE id = p_condition_id AND is_active
  ) THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_CONDITION';
  END IF;

  IF p_color_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.product_colors
    WHERE id = p_color_id AND is_active
  ) THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_COLOR';
  END IF;

  IF p_size_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.product_sizes
    WHERE id = p_size_id AND is_active
  ) THEN
    RAISE EXCEPTION 'INVALID_PRODUCT_SIZE';
  END IF;

  IF p_price IS NULL OR p_price <= 0 THEN
    RAISE EXCEPTION 'INVALID_PRICE';
  END IF;

  IF p_weight_kg IS NOT NULL AND (p_weight_kg <= 0 OR p_weight_kg > 10) THEN
    RAISE EXCEPTION 'WEIGHT_LIMIT_EXCEEDED';
  END IF;

  IF coalesce(p_audience, 'public') NOT IN ('public', 'followers', 'private') THEN
    RAISE EXCEPTION 'INVALID_AUDIENCE';
  END IF;

  SELECT id INTO v_currency
  FROM public.currencies
  WHERE code = 'EGP' AND is_active;

  SELECT id INTO v_status
  FROM public.product_statuses
  WHERE slug = 'pending_review' AND is_active;

  IF v_currency IS NULL OR v_status IS NULL THEN
    RAISE EXCEPTION 'REFERENCE_DATA_NOT_READY';
  END IF;

  INSERT INTO public.products (
    seller_id, category_id, title_ar, title_en, description_ar, description_en,
    price, currency_id, condition_id, color_id, size_id, status_id, brand_name,
    weight_kg, audience, moderation_status, published_at
  )
  VALUES (
    p_seller_profile_id, p_category_id, trim(p_title_ar), nullif(trim(p_title_en), ''),
    p_description_ar, p_description_en, p_price, v_currency, p_condition_id, p_color_id,
    p_size_id, v_status, nullif(trim(p_brand_name), ''), p_weight_kg,
    coalesce(p_audience, 'public'), 'pending', NULL
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END
$function$;
