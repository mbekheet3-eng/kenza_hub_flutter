-- Allow the seller notification generated when a buyer completes an order.
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check
  CHECK (type = ANY (ARRAY[
    'new_message',
    'new_offer',
    'offer_accepted',
    'offer_rejected',
    'new_order',
    'order_accepted',
    'order_rejected',
    'order_updated',
    'order_reminder',
    'order_expired',
    'order_completed'
  ]::text[]));
