revoke all on table public.profiles from public, anon, authenticated;
revoke all on table public.categories from public, anon, authenticated;
revoke all on table public.products from public, anon, authenticated;
revoke all on table public.product_images from public, anon, authenticated;

grant select, insert, update
  on table public.profiles to authenticated;

grant select
  on table public.categories to anon, authenticated;

grant select
  on table public.products to anon, authenticated;
grant insert, update, delete
  on table public.products to authenticated;

grant select
  on table public.product_images to anon, authenticated;
grant insert, update, delete
  on table public.product_images to authenticated;
