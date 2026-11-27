-- Prevent duplicate stock rows that differ only by color/size letter case.
drop index if exists public.product_variants_unique_combination;
create unique index product_variants_unique_combination
on public.product_variants(product_id, lower(coalesce(color,'')), lower(coalesce(size,'')));
