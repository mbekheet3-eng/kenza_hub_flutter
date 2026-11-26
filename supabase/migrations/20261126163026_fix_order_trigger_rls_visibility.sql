-- Keep insert and accept checks compatible with product SELECT RLS.
-- Row locking on products requires update visibility and can hide valid listings
-- from buyers who are allowed to read but not update those products.
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

  PERFORM pg_advisory_xact_lock(
    hashtextextended(NEW.product_id::text || ':' || auth.uid()::text, 0)
  );

  IF EXISTS (
    SELECT 1
    FROM public.product_orders o
    WHERE o.product_id = NEW.product_id
      AND o.buyer_id = auth.uid()
      AND o.status IN ('pending', 'accepted')
  ) THEN
    RAISE EXCEPTION 'An active purchase request already exists for this product'
      USING ERRCODE = '23505';
  END IF;

  SELECT p.owner_id, p.price, p.currency, p.status
    INTO v_owner_id, v_price, v_currency, v_product_status
  FROM public.products p
  WHERE p.id = NEW.product_id;

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
  WHERE p.id = NEW.product_id;

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
      WHERE p.id = NEW.product_id;

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
