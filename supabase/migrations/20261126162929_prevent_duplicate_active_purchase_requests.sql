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

  -- Serialize concurrent requests from the same buyer for the same product.
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
