alter table public.products
  add column if not exists custom_category_name text;
