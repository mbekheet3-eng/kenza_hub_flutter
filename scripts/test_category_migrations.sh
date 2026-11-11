#!/usr/bin/env bash
set -euo pipefail

: "${PGHOST:=127.0.0.1}"
: "${PGPORT:=5432}"
: "${PGUSER:=postgres}"
: "${PGPASSWORD:=postgres}"
: "${PGDATABASE:=postgres}"
export PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE

psql -v ON_ERROR_STOP=1 <<'SQL'
create extension if not exists pgcrypto;

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete set null,
  name_ar text not null,
  name_en text not null,
  slug text not null unique,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.categories (name_ar, name_en, slug, sort_order, is_active)
values
  ('ملابس', 'Clothes', 'clothes', 1, true),
  ('أحذية', 'Shoes', 'shoes', 2, true),
  ('مستلزمات الأطفال', 'Children Supplies', 'children-supplies', 3, true),
  ('مستلزمات المنزل', 'Home Supplies', 'home-supplies', 4, true);
SQL

# Supabase applies each migration transactionally. Keep that behavior here because
# the category expansion uses a temporary translation table with ON COMMIT DROP.
for migration in \
  supabase/migrations/20261110010000_add_french_category_names.sql \
  supabase/migrations/20261110011000_require_all_category_translations.sql \
  supabase/migrations/20261110233041_expand_marketplace_category_tree.sql \
  supabase/migrations/20261110233452_fix_category_tree_sort_order.sql
do
  {
    printf 'BEGIN;\n'
    cat "$migration"
    printf '\nCOMMIT;\n'
  } | psql -v ON_ERROR_STOP=1
done

psql -v ON_ERROR_STOP=1 <<'SQL'
do $$
begin
  if exists (
    select 1 from public.categories
    where name_fr is null or btrim(name_fr) = ''
  ) then
    raise exception 'A category has a missing French translation';
  end if;

  if not exists (
    select 1 from public.categories
    where slug = 'clothes-women-evening-dresses'
      and name_fr = 'Robes de soirée'
  ) then
    raise exception 'French translation for evening dresses is missing';
  end if;

  if not exists (
    select 1 from public.categories
    where slug = 'clothes-other-uniforms'
      and name_fr = 'Uniformes'
  ) then
    raise exception 'French translation for uniforms is missing';
  end if;

  if not exists (
    select 1 from public.categories
    where slug = 'home-furniture-other'
      and name_fr = 'Autres'
  ) then
    raise exception 'French fallback for Other categories is missing';
  end if;

  if not exists (
    select 1
    from public.categories child
    join public.categories parent on parent.id = child.parent_id
    where child.slug = 'clothes-women-evening-dresses'
      and parent.slug = 'clothes-women'
  ) then
    raise exception 'The nested women category hierarchy is incorrect';
  end if;
end;
$$;
SQL

echo "Category migrations smoke test passed."
