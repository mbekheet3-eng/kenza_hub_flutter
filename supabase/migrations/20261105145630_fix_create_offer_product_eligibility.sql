CREATE OR REPLACE FUNCTION private.create_offer(
  p_product_id uuid,
  p_offered_price numeric,
  p_expires_at timestamp with time zone DEFAULT NULL::timestamp with time zone
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_seller uuid;
  v_id uuid;
  v_audience text;
  v_product_price numeric;
BEGIN
  IF auth.uid() IS NULL OR NOT private.is_active_user() THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  SELECT p.seller_id, p.audience, p.price
    INTO v_seller, v_audience, v_product_price
  FROM public.products p
  JOIN public.product_statuses ps ON ps.id = p.status_id
  JOIN public.seller_profiles sp ON sp.id = p.seller_id
  WHERE p.id = p_product_id
    AND p.moderation_status = 'approved'
    AND ps.slug = 'available'
    AND ps.is_active
    AND sp.is_active;

  IF v_seller IS NULL THEN
    RAISE EXCEPTION 'PRODUCT_NOT_AVAILABLE';
  END IF;

  IF NOT (
    v_audience = 'public'
    OR (
      v_audience = 'followers'
      AND EXISTS (
        SELECT 1
        FROM public.follows f
        WHERE f.follower_user_id = auth.uid()
          AND f.followed_seller_profile_id = v_seller
      )
    )
  ) THEN
    RAISE EXCEPTION 'PRODUCT_NOT_AVAILABLE';
  END IF;

  IF private.has_seller_permission(v_seller, 'products:read') THEN
    RAISE EXCEPTION 'SELF_OFFER_NOT_ALLOWED';
  END IF;

  IF p_offered_price IS NULL
     OR p_offered_price <= 0
     OR p_offered_price >= v_product_price THEN
    RAISE EXCEPTION 'INVALID_OFFER_PRICE';
  END IF;

  INSERT INTO public.offers (
    product_id,
    seller_profile_id,
    buyer_user_id,
    offered_price,
    expires_at
  )
  VALUES (
    p_product_id,
    v_seller,
    auth.uid(),
    p_offered_price,
    p_expires_at
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END
$function$;

REVOKE EXECUTE ON FUNCTION private.create_offer(uuid, numeric, timestamptz) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.create_offer(uuid, numeric, timestamptz) TO authenticated;