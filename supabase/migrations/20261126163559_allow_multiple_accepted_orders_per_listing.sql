-- Listings may represent stock with multiple units; do not assume one accepted order per listing.
DROP INDEX IF EXISTS public.product_orders_one_accepted_per_product;
