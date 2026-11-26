-- Add a seller delivery confirmation before the buyer can complete an order.
ALTER TABLE public.product_orders
  DROP CONSTRAINT IF EXISTS product_orders_status_check;

ALTER TABLE public.product_orders
  ADD CONSTRAINT product_orders_status_check
  CHECK (status = ANY (ARRAY[
    'pending', 'accepted', 'rejected', 'cancelled',
    'delivered', 'completed', 'expired'
  ]::text[]));

DROP POLICY IF EXISTS "Seller can accept or reject pending order"
  ON public.product_orders;
CREATE POLICY "Seller can respond to pending or accepted order"
ON public.product_orders
FOR UPDATE
TO authenticated
USING (
  (SELECT auth.uid()) = seller_id
  AND status IN ('pending', 'accepted')
)
WITH CHECK (
  (SELECT auth.uid()) = seller_id
  AND status IN ('accepted', 'rejected', 'delivered')
);

DROP POLICY IF EXISTS "Buyer can complete accepted order"
  ON public.product_orders;
CREATE POLICY "Buyer can complete delivered order"
ON public.product_orders
FOR UPDATE
TO authenticated
USING (
  (SELECT auth.uid()) = buyer_id
  AND status = 'delivered'
)
WITH CHECK (
  (SELECT auth.uid()) = buyer_id
  AND status = 'completed'
);

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
      OR (OLD.status = 'accepted' AND NEW.status = 'delivered')
      OR (OLD.status = 'delivered' AND NEW.status = 'completed')
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

CREATE OR REPLACE FUNCTION public.notify_order_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM public.create_user_notification(
      NEW.seller_id, 'new_order', 'طلب شراء جديد',
      'لديك طلب شراء جديد لأحد منتجاتك',
      jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
      'order:' || NEW.id::text || ':created'
    );
  ELSIF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NEW.status = 'accepted' THEN
      PERFORM public.create_user_notification(
        NEW.buyer_id, 'order_accepted', 'تم قبول طلب الشراء',
        'وافق البائع على طلب الشراء',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
        'order:' || NEW.id::text || ':accepted'
      );
    ELSIF NEW.status = 'rejected' THEN
      PERFORM public.create_user_notification(
        NEW.buyer_id, 'order_rejected', 'تم رفض طلب الشراء',
        'لم يوافق البائع على طلب الشراء',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
        'order:' || NEW.id::text || ':rejected'
      );
    ELSIF NEW.status = 'expired' THEN
      PERFORM public.create_user_notification(
        NEW.buyer_id, 'order_expired', 'انتهت صلاحية طلب الشراء',
        'انتهت مهلة 48 ساعة دون رد من البائع',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
        'order:' || NEW.id::text || ':expired:buyer'
      );
      PERFORM public.create_user_notification(
        NEW.seller_id, 'order_expired', 'انتهت صلاحية طلب شراء',
        'انتهت مهلة الرد على طلب الشراء',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
        'order:' || NEW.id::text || ':expired:seller'
      );
    ELSIF NEW.status = 'cancelled' THEN
      PERFORM public.create_user_notification(
        NEW.seller_id, 'order_updated', 'تحديث طلب الشراء',
        'ألغى المشتري طلب الشراء',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
        'order:' || NEW.id::text || ':cancelled'
      );
    ELSIF NEW.status = 'delivered' THEN
      PERFORM public.create_user_notification(
        NEW.buyer_id, 'order_delivered', 'أكد البائع تسليم المنتج',
        'يرجى فحص المنتج ثم تأكيد الاستلام لإتمام الطلب',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
        'order:' || NEW.id::text || ':delivered:buyer'
      );
    ELSIF NEW.status = 'completed' THEN
      PERFORM public.create_user_notification(
        NEW.seller_id, 'order_completed', 'تم استلام المنتج',
        'أكد المشتري استلام المنتج وإتمام طلب الشراء',
        jsonb_build_object('order_id', NEW.id, 'product_id', NEW.product_id),
        'order:' || NEW.id::text || ':completed:seller'
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type = ANY (ARRAY[
    'new_message', 'new_offer', 'offer_accepted', 'offer_rejected',
    'new_order', 'order_accepted', 'order_rejected', 'order_updated',
    'order_reminder', 'order_expired', 'order_delivered', 'order_completed'
  ]::text[]));
