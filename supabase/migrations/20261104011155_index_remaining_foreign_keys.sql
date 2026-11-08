
create index if not exists carts_seller_profile_fk_idx on public.carts(seller_profile_id);
create index if not exists courier_profiles_created_by_fk_idx on public.courier_profiles(created_by);
