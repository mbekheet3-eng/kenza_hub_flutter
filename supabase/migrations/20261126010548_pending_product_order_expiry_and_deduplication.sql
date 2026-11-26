-- Recovered source for the live pending-order expiry and deduplication migration.
ALTER TABLE public.product_orders
  ADD COLUMN IF NOT EXISTS expires_at timestamptz;

ALTER TABLE public.product_orders
  ADD COLUMN IF NOT EXISTS reminder_sent_at timestamptz;

ALTER TABLE public.product_orders
  DROP CONSTRAINT IF EXISTS product_orders_status_check;

ALTER TABLE public.product_orders
  ADD CONSTRAINT product_orders_status_check
  CHECK (status = ANY (ARRAY[
    'pending',
    'accepted',
    'rejected',
    'cancelled',
    'completed',
    'expired'
  ]::text[]));

CREATE OR REPLACE FUNCTION public.set_product_order_expiry()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $function$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.expires_at := NEW.created_at + interval '48 hours';
    NEW.reminder_sent_at := NULL;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_set_product_order_expiry ON public.product_orders;
CREATE TRIGGER trg_set_product_order_expiry
BEFORE INSERT ON public.product_orders
FOR EACH ROW EXECUTE FUNCTION public.set_product_order_expiry();

CREATE OR REPLACE FUNCTION public.process_pending_product_orders()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $function$
BEGIN
  UPDATE public.product_orders
  SET status = 'expired', updated_at = now()
  WHERE status = 'pending'
    AND expires_at <= now();

  WITH due AS (
    UPDATE public.product_orders
    SET reminder_sent_at = now()
    WHERE status = 'pending'
      AND created_at <= now() - interval '24 hours'
      AND expires_at > now()
      AND reminder_sent_at IS NULL
    RETURNING id, product_id, seller_id
  )
  INSERT INTO public.notifications(user_id, type, title, body, data, event_key)
  SELECT seller_id, 'order_reminder', 'تذكير بطلب شراء معلق',
         'لديك طلب شراء ينتظر ردك منذ 24 ساعة',
         jsonb_build_object('order_id', id, 'product_id', product_id),
         'order:' || id::text || ':reminder'
  FROM due
  ON CONFLICT (event_key) DO NOTHING;
END;
$function$;

CREATE UNIQUE INDEX IF NOT EXISTS product_orders_one_pending_per_buyer_product
ON public.product_orders (product_id, buyer_id)
WHERE status = 'pending';

SELECT cron.unschedule(jobid)
FROM cron.job
WHERE jobname = 'kenza-process-pending-product-orders';

SELECT cron.schedule(
  'kenza-process-pending-product-orders',
  '*/15 * * * *',
  'select public.process_pending_product_orders();'
);
