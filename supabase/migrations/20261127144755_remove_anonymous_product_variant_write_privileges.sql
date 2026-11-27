-- Anonymous users may read variants of published products only.
-- Variant writes are reserved for authenticated Pro Seller owners via RLS.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.product_variants FROM anon;
