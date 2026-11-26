-- Notify the seller when the buyer confirms receipt and completes an order.
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
