CREATE OR REPLACE FUNCTION private.add_to_cart(p_product_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid := auth.uid();
  v_seller uuid;
  v_price numeric;
  v_cart uuid;
  v_item uuid;
BEGIN
  IF v_uid IS NULL OR NOT private.is_active_user() THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  SELECT p.seller_id, p.price
    INTO v_seller, v_price
  FROM public.products p
  JOIN public.product_statuses ps ON ps.id = p.status_id
  JOIN public.seller_profiles sp ON sp.id = p.seller_id
  WHERE p.id = p_product_id
    AND p.moderation_status = 'approved'
    AND ps.slug = 'available'
    AND ps.is_active
    AND p.audience = 'public'
    AND sp.is_active;

  IF v_seller IS NULL THEN
    RAISE EXCEPTION 'PRODUCT_NOT_AVAILABLE';
  END IF;

  IF private.has_seller_permission(v_seller, 'products:read') THEN
    RAISE EXCEPTION 'SELF_PURCHASE_NOT_ALLOWED';
  END IF;

  INSERT INTO public.carts(user_id, seller_profile_id)
  VALUES (v_uid, v_seller)
  ON CONFLICT (user_id, seller_profile_id)
  DO UPDATE SET updated_at = now()
  RETURNING id INTO v_cart;

  INSERT INTO public.cart_items(cart_id, product_id, quantity, unit_price_at_add)
  VALUES (v_cart, p_product_id, 1, v_price)
  ON CONFLICT (cart_id, product_id)
  DO UPDATE SET unit_price_at_add = EXCLUDED.unit_price_at_add
  RETURNING id INTO v_item;

  RETURN v_cart;
END
$function$;
