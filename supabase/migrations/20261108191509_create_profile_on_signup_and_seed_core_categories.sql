create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'avatar_url'), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public;
revoke all on function public.handle_new_user() from anon, authenticated;
grant execute on function public.handle_new_user() to supabase_auth_admin;

drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.categories (name_ar, name_en, slug, sort_order, is_active)
values
  ('ملابس', 'Clothes', 'clothes', 1, true),
  ('أحذية', 'Shoes', 'shoes', 2, true),
  ('مستلزمات الأطفال', 'Children Supplies', 'children-supplies', 3, true),
  ('مستلزمات المنزل', 'Home Supplies', 'home-supplies', 4, true)
on conflict (slug) do update
set name_ar = excluded.name_ar,
    name_en = excluded.name_en,
    sort_order = excluded.sort_order,
    is_active = excluded.is_active;
