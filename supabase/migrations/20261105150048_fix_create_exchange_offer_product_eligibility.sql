-- Require both products in an exchange offer to be approved and actively available.
CREATE OR REPLACE FUNCTION private.create_exchange_offer(
  p_source_seller_profile_id uuid,
  p_target_seller_profile_id uuid,
  p_offered_product_id uuid,
  p_requested_product_id uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_id uuid;
BEGIN
  IF NOT private.has_seller_permission(p_source_seller_profile_id, 'exchange:manage') THEN
    RAISE EXCEPTION 'EXCHANGE_PERMISSION_REQUIRED';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.seller_profiles
    WHERE id = p_source_seller_profile_id
      AND seller_type = 'pro_seller'
      AND is_active
  ) THEN
    RAISE EXCEPTION 'PRO_SELLER_ONLY';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.seller_profiles
    WHERE id = p_target_seller_profile_id
      AND seller_type = 'pro_seller'
      AND is_active
  ) THEN
    RAISE EXCEPTION 'TARGET_MUST_BE_PRO_SELLER';
  END IF;

  IF p_source_seller_profile_id = p_target_seller_profile_id THEN
    RAISE EXCEPTION 'SAME_SELLER_NOT_ALLOWED';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.products p
    JOIN public.product_statuses ps ON ps.id = p.status_id
    WHERE p.id = p_offered_product_id
      AND p.seller_id = p_source_seller_profile_id
      AND p.moderation_status = 'approved'
      AND ps.slug = 'available'
      AND ps.is_active
  ) THEN
    RAISE EXCEPTION 'OFFERED_PRODUCT_NOT_OWNED_OR_UNAVAILABLE';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.products p
    JOIN public.product_statuses ps ON ps.id = p.status_id
    WHERE p.id = p_requested_product_id
      AND p.seller_id = p_target_seller_profile_id
      AND p.moderation_status = 'approved'
      AND ps.slug = 'available'
      AND ps.is_active
  ) THEN
    RAISE EXCEPTION 'REQUESTED_PRODUCT_NOT_OWNED_OR_UNAVAILABLE';
  END IF;

  INSERT INTO public.exchange_offers(
    proposer_seller_profile_id,
    target_seller_profile_id,
    offered_product_id,
    requested_product_id
  )
  VALUES (
    p_source_seller_profile_id,
    p_target_seller_profile_id,
    p_offered_product_id,
    p_requested_product_id
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$function$;
