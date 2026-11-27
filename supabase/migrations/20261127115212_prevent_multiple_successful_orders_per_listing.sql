-- Prevent two buyers from successfully purchasing the same single-unit listing.
-- Pending requests may coexist; only one request may reach accepted/delivered/completed.
-- This partial unique index is concurrency-safe and makes the database the final authority.
-- Existing accepted-or-later duplicates were checked before creating this index (none found).

create unique index if not exists product_orders_one_successful_order_per_product
  on public.product_orders (product_id)
  where status in ('accepted', 'delivered', 'completed');

comment on index public.product_orders_one_successful_order_per_product is
  'Ensures a single-unit listing can have only one accepted, delivered, or completed order.';
