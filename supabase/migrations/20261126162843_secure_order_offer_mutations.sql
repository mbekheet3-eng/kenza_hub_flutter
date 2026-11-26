-- Make the database authoritative for purchase-order and offer identity/status fields.
CREATE OR REPLACE FUNCTION public.validate_product_order_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_owner_id uuid;
  v_price numeric;
  v_currency text;
  v_product_status text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT p.owner_id, p.price, p.currency, p.status
    INTO v_owner_id, v_price, v_currency, v_product_status
  FROM public.products p
  WHERE p.id = NEW.product_id
  FOR SHARE;

  IF NOT FOUND OR v_product_status <> 'published' THEN
    RAISE EXCEPTION 'Product is not available for purchase' USING ERRCODE = '23514';
  END IF;

  IF v_owner_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot purchase your own product' USING ERRCODE = '23514';
  END IF;

  IF v_price <= 0 THEN
    RAISE EXCEPTION 'Product price must be greater than zero' USING ERRCODE = '23514';
  END IF;

  NEW.buyer_id := auth.uid();
  NEW.seller_id := v_owner_id;
  NEW.agreed_price := v_price;
  NEW.currency := v_currency;
  NEW.status := 'pending';
  NEW.created_at := now();
  NEW.updated_at := now();
  NEW.expires_at := now() + interval '48 hours';
  NEW.reminder_sent_at := NULL;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.validate_product_offer_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_owner_id uuid;
  v_currency text;
  v_product_status text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT p.owner_id, p.currency, p.status
    INTO v_owner_id, v_currency, v_product_status
  FROM public.products p
  WHERE p.id = NEW.product_id
  FOR SHARE;

  IF NOT FOUND OR v_product_status <> 'published' THEN
    RAISE EXCEPTION 'Product is not available for offers' USING ERRCODE = '23514';
  END IF;

  IF v_owner_id = auth.uid() THEN
    RAISE EXCEPTION 'You cannot make an offer on your own product' USING ERRCODE = '23514';
  END IF;

  NEW.buyer_id := auth.uid();
  NEW.seller_id := v_owner_id;
  NEW.currency := v_currency;
  NEW.status := 'pending';
  NEW.created_at := now();
  NEW.updated_at := now();

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.validate_product_order_status_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_owner_id uuid;
  v_price numeric;
  v_currency text;
  v_product_status text;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT (
      (OLD.status = 'pending' AND NEW.status IN ('accepted', 'rejected', 'cancelled', 'expired'))
      OR (OLD.status = 'accepted' AND NEW.status = 'completed')
    ) THEN
      RAISE EXCEPTION 'Invalid purchase-order status transition: % -> %', OLD.status, NEW.status
        USING ERRCODE = '23514';
    END IF;

    IF NEW.status = 'accepted' THEN
      SELECT p.owner_id, p.price, p.currency, p.status
        INTO v_owner_id, v_price, v_currency, v_product_status
      FROM public.products p
      WHERE p.id = NEW.product_id
      FOR SHARE;

      IF NOT FOUND
        OR v_product_status <> 'published'
        OR v_owner_id <> NEW.seller_id
        OR v_price <> NEW.agreed_price
        OR v_currency <> NEW.currency THEN
        RAISE EXCEPTION 'The product price or availability changed; refresh the listing before accepting'
          USING ERRCODE = '23514';
      END IF;
    END IF;
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.validate_product_offer_status_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT (
      OLD.status = 'pending'
      AND NEW.status IN ('accepted', 'rejected', 'withdrawn', 'expired')
    ) THEN
      RAISE EXCEPTION 'Invalid offer status transition: % -> %', OLD.status, NEW.status
        USING ERRCODE = '23514';
    END IF;
  END IF;

  NEW.updated_at := now();
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_validate_product_order_insert ON public.product_orders;
CREATE TRIGGER trg_validate_product_order_insert
BEFORE INSERT ON public.product_orders
FOR EACH ROW EXECUTE FUNCTION public.validate_product_order_insert();

DROP TRIGGER IF EXISTS trg_validate_product_offer_insert ON public.product_offers;
CREATE TRIGGER trg_validate_product_offer_insert
BEFORE INSERT ON public.product_offers
FOR EACH ROW EXECUTE FUNCTION public.validate_product_offer_insert();

DROP TRIGGER IF EXISTS trg_validate_product_order_status_transition ON public.product_orders;
CREATE TRIGGER trg_validate_product_order_status_transition
BEFORE UPDATE OF status ON public.product_orders
FOR EACH ROW EXECUTE FUNCTION public.validate_product_order_status_transition();

DROP TRIGGER IF EXISTS trg_validate_product_offer_status_transition ON public.product_offers;
CREATE TRIGGER trg_validate_product_offer_status_transition
BEFORE UPDATE OF status ON public.product_offers
FOR EACH ROW EXECUTE FUNCTION public.validate_product_offer_status_transition();

-- The seller can accept only one purchase order for a single-item listing at a time.
CREATE UNIQUE INDEX IF NOT EXISTS product_orders_one_accepted_per_product
ON public.product_orders (product_id)
WHERE status = 'accepted';

-- Keep existing clients compatible while preventing any authenticated user from
-- changing price, participants, timestamps, or other immutable transaction fields.
REVOKE UPDATE ON TABLE public.product_orders FROM PUBLIC, anon, authenticated;
GRANT UPDATE (status) ON TABLE public.product_orders TO authenticated;

REVOKE UPDATE ON TABLE public.product_offers FROM PUBLIC, anon, authenticated;
GRANT UPDATE (status) ON TABLE public.product_offers TO authenticated;

-- These are trigger-only SECURITY DEFINER functions, not client RPC endpoints.
REVOKE EXECUTE ON FUNCTION public.guard_product_publication_with_moderation()
  FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.reset_product_moderation_after_image_change()
  FROM PUBLIC, anon, authenticated;
