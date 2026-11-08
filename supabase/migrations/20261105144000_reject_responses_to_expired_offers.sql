-- Reject seller responses to pending offers whose expiry time has passed.
CREATE OR REPLACE FUNCTION private.respond_offer(p_offer_id uuid, p_decision text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_seller uuid;
  v_expires_at timestamptz;
BEGIN
  IF p_decision IS NULL OR p_decision NOT IN ('accepted', 'rejected') THEN
    RAISE EXCEPTION 'INVALID_DECISION';
  END IF;

  SELECT seller_profile_id, expires_at
    INTO v_seller, v_expires_at
    FROM public.offers
   WHERE id = p_offer_id
     AND status = 'pending'
   FOR UPDATE;

  IF v_seller IS NULL THEN
    RAISE EXCEPTION 'OFFER_NOT_PENDING';
  END IF;

  IF NOT private.is_seller_owner(v_seller) THEN
    RAISE EXCEPTION 'SELLER_OWNER_ONLY';
  END IF;

  IF v_expires_at IS NOT NULL AND v_expires_at <= now() THEN
    RAISE EXCEPTION 'OFFER_EXPIRED';
  END IF;

  UPDATE public.offers
     SET status = p_decision,
         responded_at = now()
   WHERE id = p_offer_id;
END;
$function$;
