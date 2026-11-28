-- Product condition, non-variant stock, coarse product location, and offer lifecycle.
-- Location is a seller-entered city/area only; do not store street addresses.
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS condition text,
  ADD COLUMN IF NOT EXISTS location text,
  ADD COLUMN IF NOT EXISTS quantity integer NOT NULL DEFAULT 1;

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_condition_check;
ALTER TABLE public.products
  ADD CONSTRAINT products_condition_check
  CHECK (condition IS NULL OR condition IN ('new', 'used'));

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_location_length_check;
ALTER TABLE public.products
  ADD CONSTRAINT products_location_length_check
  CHECK (location IS NULL OR char_length(btrim(location)) <= 80);

ALTER TABLE public.products
  DROP CONSTRAINT IF EXISTS products_quantity_positive;
ALTER TABLE public.products
  ADD CONSTRAINT products_quantity_positive CHECK (quantity > 0);

ALTER TABLE public.product_offers
  ADD COLUMN IF NOT EXISTS counter_price numeric,
  ADD COLUMN IF NOT EXISTS counter_message text,
  ADD COLUMN IF NOT EXISTS countered_at timestamptz;

ALTER TABLE public.product_offers
  DROP CONSTRAINT IF EXISTS product_offers_counter_price_positive;
ALTER TABLE public.product_offers
  ADD CONSTRAINT product_offers_counter_price_positive
  CHECK (counter_price IS NULL OR counter_price > 0);

ALTER TABLE public.product_orders
  ADD COLUMN IF NOT EXISTS source_offer_id uuid
  REFERENCES public.product_offers(id) ON DELETE RESTRICT;

CREATE UNIQUE INDEX IF NOT EXISTS product_orders_source_offer_id_unique
  ON public.product_orders(source_offer_id)
  WHERE source_offer_id IS NOT NULL;

-- Inventory is now serialized by locking the product row during acceptance.
-- A quantity of one still behaves exactly like the former single-unit listing.
DROP INDEX IF EXISTS public.product_orders_one_successful_order_per_product;

CREATE OR REPLACE FUNCTION public.validate_product_order_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $function$
DECLARE
  v_buyer_id uuid;
  v_seller_id uuid;
  v_owner_id uuid;
  v_price numeric;
  v_currency text;
  v_product_status text;
  v_has_variants boolean;
  v_product_quantity integer;
  v_reserved_by_order_id uuid;
  v_available integer;
  v_variant_color text;
  v_variant_size text;
  v_offer public.product_offers%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  IF NEW.source_offer_id IS NOT NULL THEN
    SELECT * INTO v_offer
    FROM public.product_offers
    WHERE id = NEW.source_offer_id
    FOR UPDATE;

    IF NOT FOUND OR v_offer.status <> 'accepted'
       OR auth.uid() NOT IN (v_offer.buyer_id, v_offer.seller_id)
       OR v_offer.product_id <> NEW.product_id THEN
      RAISE EXCEPTION 'Accepted offer not found or not accessible'
        USING ERRCODE = '42501';
    END IF;
    v_buyer_id := v_offer.buyer_id;
    v_seller_id := v_offer.seller_id;
    NEW.quantity := 1;
  ELSE
    v_buyer_id := auth.uid();
  END IF;

  PERFORM pg_advisory_xact_lock(
    hashtextextended(NEW.product_id::text || ':' || v_buyer_id::text, 0)
  );

  IF EXISTS (
    SELECT 1
    FROM public.product_orders o
    WHERE o.product_id = NEW.product_id
      AND o.buyer_id = v_buyer_id
      AND o.status IN ('pending', 'accepted', 'delivered')
  ) THEN
    RAISE EXCEPTION 'An active purchase request already exists for this product'
      USING ERRCODE = '23505';
  END IF;

  SELECT p.owner_id, p.price, p.currency, p.status, p.has_variants,
         p.quantity, p.reserved_by_order_id
    INTO v_owner_id, v_price, v_currency, v_product_status, v_has_variants,
         v_product_quantity, v_reserved_by_order_id
  FROM public.products p
  WHERE p.id = NEW.product_id
  FOR UPDATE;

  IF NOT FOUND OR v_product_status <> 'published' THEN
    RAISE EXCEPTION 'Product is not available for purchase' USING ERRCODE = '23514';
  END IF;

  IF v_seller_id IS NOT NULL AND v_seller_id <> v_owner_id THEN
    RAISE EXCEPTION 'Offer seller no longer owns this product' USING ERRCODE = '23514';
  END IF;
  v_seller_id := v_owner_id;

  IF v_buyer_id = v_owner_id THEN
    RAISE EXCEPTION 'You cannot purchase your own product' USING ERRCODE = '23514';
  END IF;

  IF v_price <= 0 OR v_product_quantity < 1 OR v_reserved_by_order_id IS NOT NULL THEN
    RAISE EXCEPTION 'out_of_stock' USING ERRCODE = '23514';
  END IF;

  IF NEW.source_offer_id IS NOT NULL THEN
    IF v_has_variants THEN
      RAISE EXCEPTION 'Offers are not available for listings with size or color options'
        USING ERRCODE = '23514';
    END IF;
    NEW.variant_id := NULL;
    NEW.variant_color := NULL;
    NEW.variant_size := NULL;
    NEW.agreed_price := COALESCE(v_offer.counter_price, v_offer.offered_price);
    NEW.currency := v_offer.currency;
  ELSIF v_has_variants THEN
    IF NEW.variant_id IS NULL OR NEW.quantity < 1 THEN
      RAISE EXCEPTION 'Choose a product variant and quantity' USING ERRCODE = '23514';
    END IF;
    SELECT v.quantity, v.color, v.size
      INTO v_available, v_variant_color, v_variant_size
    FROM public.product_variants v
    WHERE v.id = NEW.variant_id AND v.product_id = NEW.product_id;
    IF NOT FOUND OR NEW.quantity > v_available THEN
      RAISE EXCEPTION 'out_of_stock' USING ERRCODE = '23514';
    END IF;
    NEW.variant_color := v_variant_color;
    NEW.variant_size := v_variant_size;
    NEW.agreed_price := v_price * NEW.quantity;
    NEW.currency := v_currency;
  ELSE
    IF NEW.variant_id IS NOT NULL OR NEW.quantity < 1 OR NEW.quantity > v_product_quantity THEN
      RAISE EXCEPTION 'out_of_stock' USING ERRCODE = '23514';
    END IF;
    NEW.variant_color := NULL;
    NEW.variant_size := NULL;
    NEW.agreed_price := v_price * NEW.quantity;
    NEW.currency := v_currency;
  END IF;

  NEW.buyer_id := v_buyer_id;
  NEW.seller_id := v_seller_id;
  NEW.status := 'pending';
  NEW.created_at := now();
  NEW.updated_at := now();
  NEW.expires_at := now() + interval '48 hours';
  NEW.reminder_sent_at := NULL;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.validate_product_order_status_transition()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_owner_id uuid;
  v_price numeric;
  v_currency text;
  v_product_status text;
  v_has_variants boolean;
  v_product_quantity integer;
  v_expected_price numeric;
  v_offer public.product_offers%ROWTYPE;
  v_rows integer;
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT (
      (OLD.status = 'pending' AND NEW.status IN ('accepted', 'rejected', 'cancelled', 'expired'))
      OR (OLD.status = 'accepted' AND NEW.status IN ('cancelled', 'expired', 'delivered'))
      OR (OLD.status = 'delivered' AND NEW.status = 'completed')
    ) THEN
      RAISE EXCEPTION 'Invalid purchase-order status transition: % -> %', OLD.status, NEW.status
        USING ERRCODE = '23514';
    END IF;

    IF NEW.status = 'accepted' THEN
      SELECT p.owner_id, p.price, p.currency, p.status, p.has_variants, p.quantity
        INTO v_owner_id, v_price, v_currency, v_product_status, v_has_variants, v_product_quantity
      FROM public.products p
      WHERE p.id = NEW.product_id
      FOR UPDATE;

      IF NEW.source_offer_id IS NULL THEN
        v_expected_price := v_price * NEW.quantity;
      ELSE
        SELECT * INTO v_offer
        FROM public.product_offers
        WHERE id = NEW.source_offer_id AND status = 'accepted';
        IF NOT FOUND OR v_offer.product_id <> NEW.product_id
           OR v_offer.buyer_id <> NEW.buyer_id OR v_offer.seller_id <> NEW.seller_id THEN
          RAISE EXCEPTION 'Accepted offer no longer matches this order' USING ERRCODE = '23514';
        END IF;
        v_expected_price := COALESCE(v_offer.counter_price, v_offer.offered_price);
      END IF;

      IF v_owner_id IS NULL OR v_product_status <> 'published' OR v_owner_id <> NEW.seller_id
        OR v_expected_price <> NEW.agreed_price OR v_currency <> NEW.currency
        OR v_has_variants <> (NEW.variant_id IS NOT NULL) THEN
        RAISE EXCEPTION 'The product price or availability changed; refresh the listing before accepting'
          USING ERRCODE = '23514';
      END IF;

      IF NEW.variant_id IS NOT NULL THEN
        UPDATE public.product_variants
        SET quantity = quantity - NEW.quantity
        WHERE id = NEW.variant_id AND product_id = NEW.product_id
          AND quantity >= NEW.quantity;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        IF v_rows = 0 THEN RAISE EXCEPTION 'out_of_stock' USING ERRCODE = '23514'; END IF;
      ELSE
        UPDATE public.products
        SET quantity = quantity - NEW.quantity,
            status = CASE WHEN quantity - NEW.quantity = 0 THEN 'archived' ELSE 'published' END,
            reserved_by_order_id = CASE WHEN quantity - NEW.quantity = 0 THEN NEW.id ELSE NULL END
        WHERE id = NEW.product_id AND owner_id = NEW.seller_id
          AND status = 'published' AND reserved_by_order_id IS NULL
          AND quantity >= NEW.quantity;
        GET DIAGNOSTICS v_rows = ROW_COUNT;
        IF v_rows = 0 THEN RAISE EXCEPTION 'out_of_stock' USING ERRCODE = '23514'; END IF;
      END IF;

      NEW.hold_expires_at := now() + interval '24 hours';
      NEW.postponement_requested_at := NULL;
      NEW.postponement_requested_until := NULL;
      NEW.postponement_extension_count := 0;
      NEW.stock_restored_at := NULL;
      NEW.cancellation_reason := NULL;
      NEW.cancellation_note := NULL;

    ELSIF OLD.status = 'accepted' AND NEW.status IN ('cancelled', 'expired') THEN
      IF OLD.stock_restored_at IS NULL THEN
        IF OLD.variant_id IS NOT NULL THEN
          UPDATE public.product_variants
          SET quantity = quantity + OLD.quantity
          WHERE id = OLD.variant_id AND product_id = OLD.product_id;
        ELSE
          UPDATE public.products
          SET quantity = quantity + OLD.quantity,
              status = CASE WHEN reserved_by_order_id = OLD.id THEN 'published' ELSE status END,
              reserved_by_order_id = CASE WHEN reserved_by_order_id = OLD.id THEN NULL ELSE reserved_by_order_id END
          WHERE id = OLD.product_id
            AND (reserved_by_order_id = OLD.id OR (status = 'published' AND reserved_by_order_id IS NULL));
        END IF;
        NEW.stock_restored_at := now();
      END IF;
      NEW.postponement_requested_at := NULL;
      NEW.postponement_requested_until := NULL;

    ELSIF OLD.status = 'accepted' AND NEW.status = 'delivered' THEN
      IF OLD.variant_id IS NULL THEN
        UPDATE public.products
        SET reserved_by_order_id = NULL
        WHERE id = OLD.product_id AND reserved_by_order_id = OLD.id;
      END IF;
      NEW.postponement_requested_at := NULL;
      NEW.postponement_requested_until := NULL;
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

DROP TRIGGER IF EXISTS trg_validate_product_order_status_transition ON public.product_orders;
CREATE TRIGGER trg_validate_product_order_status_transition
BEFORE UPDATE OF status ON public.product_orders
FOR EACH ROW EXECUTE FUNCTION public.validate_product_order_status_transition();

CREATE OR REPLACE FUNCTION public.counter_product_offer(
  p_offer_id uuid,
  p_counter_price numeric,
  p_counter_message text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_offer public.product_offers%ROWTYPE;
  v_status text;
  v_has_variants boolean;
  v_quantity integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;
  IF p_counter_price IS NULL OR p_counter_price <= 0 THEN
    RAISE EXCEPTION 'Counteroffer price must be greater than zero' USING ERRCODE = '23514';
  END IF;

  SELECT * INTO v_offer FROM public.product_offers WHERE id = p_offer_id FOR UPDATE;
  IF NOT FOUND OR v_offer.seller_id <> auth.uid() OR v_offer.status <> 'pending' THEN
    RAISE EXCEPTION 'Pending offer not found or not accessible' USING ERRCODE = '42501';
  END IF;

  SELECT status, has_variants, quantity
    INTO v_status, v_has_variants, v_quantity
  FROM public.products
  WHERE id = v_offer.product_id AND owner_id = v_offer.seller_id
  FOR UPDATE;

  IF NOT FOUND OR v_status <> 'published' OR v_has_variants OR v_quantity < 1 THEN
    RAISE EXCEPTION 'This product is no longer available for a counteroffer' USING ERRCODE = '23514';
  END IF;

  UPDATE public.product_offers
  SET counter_price = p_counter_price,
      counter_message = NULLIF(btrim(p_counter_message), ''),
      countered_at = now()
  WHERE id = p_offer_id;

  PERFORM public.create_user_notification(
    v_offer.buyer_id,
    'new_offer',
    'عرض مضاد من البائع',
    'أرسل البائع عرضًا مضادًا على المنتج',
    jsonb_build_object('offer_id', p_offer_id, 'product_id', v_offer.product_id, 'counter_price', p_counter_price),
    'offer:' || p_offer_id::text || ':counter:' || extract(epoch FROM clock_timestamp())::text
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.accept_product_offer(p_offer_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_offer public.product_offers%ROWTYPE;
  v_product_status text;
  v_has_variants boolean;
  v_quantity integer;
  v_order_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_offer FROM public.product_offers WHERE id = p_offer_id FOR UPDATE;
  IF NOT FOUND OR v_offer.status <> 'pending' THEN
    RAISE EXCEPTION 'Pending offer not found' USING ERRCODE = '23514';
  END IF;

  IF auth.uid() = v_offer.seller_id THEN
    -- The seller accepts the buyer's original offer.
    NULL;
  ELSIF auth.uid() = v_offer.buyer_id AND v_offer.counter_price IS NOT NULL THEN
    -- The buyer accepts the seller's counteroffer.
    NULL;
  ELSE
    RAISE EXCEPTION 'Only the seller or the recipient of a counteroffer can accept'
      USING ERRCODE = '42501';
  END IF;

  SELECT status, has_variants, quantity
    INTO v_product_status, v_has_variants, v_quantity
  FROM public.products
  WHERE id = v_offer.product_id AND owner_id = v_offer.seller_id
  FOR UPDATE;

  IF NOT FOUND OR v_product_status <> 'published' OR v_has_variants OR v_quantity < 1 THEN
    RAISE EXCEPTION 'This product is no longer available for this offer' USING ERRCODE = '23514';
  END IF;

  UPDATE public.product_offers
  SET status = 'accepted'
  WHERE id = p_offer_id AND status = 'pending';

  INSERT INTO public.product_orders(product_id, source_offer_id, quantity)
  VALUES (v_offer.product_id, p_offer_id, 1)
  RETURNING id INTO v_order_id;

  UPDATE public.product_orders
  SET status = 'accepted'
  WHERE id = v_order_id;

  RETURN v_order_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.counter_product_offer(uuid, numeric, text) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.accept_product_offer(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.counter_product_offer(uuid, numeric, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accept_product_offer(uuid) TO authenticated;

COMMENT ON COLUMN public.products.location IS
  'Coarse seller-entered city or area only; never store a street address here.';
COMMENT ON COLUMN public.products.quantity IS
  'Available units for non-variant listings. Variant listings use product_variants.quantity.';
COMMENT ON COLUMN public.product_orders.source_offer_id IS
  'Offer accepted to create this order; null for direct purchase requests.';
