-- Enforce complete category labels in all supported app languages.
alter table public.categories
  add constraint categories_names_all_languages_not_blank
  check (
    btrim(name_ar) <> ''
    and btrim(name_en) <> ''
    and btrim(name_fr) <> ''
  );
