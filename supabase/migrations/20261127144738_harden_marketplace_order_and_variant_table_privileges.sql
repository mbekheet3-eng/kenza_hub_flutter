-- Remove bulk-destructive privileges from client-facing marketplace tables.
-- Row-level policies continue to govern normal participant actions.
REVOKE TRUNCATE ON TABLE public.product_orders, public.product_offers, public.product_variants FROM anon, authenticated;
REVOKE DELETE ON TABLE public.product_orders, public.product_offers FROM anon, authenticated;
