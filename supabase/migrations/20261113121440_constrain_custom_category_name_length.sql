alter table public.products
  add constraint products_custom_category_name_length
  check (
    custom_category_name is null
    or length(btrim(custom_category_name)) between 1 and 80
  );
