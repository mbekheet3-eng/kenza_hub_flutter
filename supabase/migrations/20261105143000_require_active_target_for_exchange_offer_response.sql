-- Prevent responding to exchange offers when the target Pro Seller store is inactive.
CREATE OR REPLACE FUNCTION private.respond_exchange_offer(p_offer_id uuid, p_decision text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_target uuid;
BEGIN
  IF p_decision IS NULL OR p_decision NOT IN ('accepted', 'rejected') THEN
    RAISE EXCEPTION 'INVALID_DECISION';
  END IF;

  SELECT target_seller_profile_id
    INTO v_target
    FROM public.exchange_offers
   WHERE id = p_offer_id
     AND status = 'pending'
   FOR UPDATE;

  IF v_target IS NULL THEN
    RAISE EXCEPTION 'OFFER_NOT_PENDING';
  END IF;

  IF NOT private.has_seller_permission(v_target, 'exchange:manage') THEN
    RAISE EXCEPTION 'TARGET_OWNER_PERMISSION_REQUIRED';
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM public.seller_profiles
     WHERE id = v_target
       AND seller_type = 'pro_seller'
  ) THEN
    RAISE EXCEPTION 'PRO_SELLER_ONLY';
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM public.seller_profiles
     WHERE id = v_target
       AND is_active = true
  ) THEN
    RAISE EXCEPTION 'TARGET_SELLER_INACTIVE';
  END IF;

  UPDATE public.exchange_offers
     SET status = p_decision
   WHERE id = p_offer_id;
END;
$function$;
