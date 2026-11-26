-- Add Miscellaneous as the fifth root category in Discover.
-- Stable slugs make this migration safe to re-run without duplicating categories.

insert into public.categories (
  parent_id, name_ar, name_en, name_fr, slug, sort_order, is_active
)
values (
  null, 'متفرقات', 'Miscellaneous', 'Divers', 'miscellaneous', 6, true
)
on conflict (slug) do update set
  parent_id = null,
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  name_fr = excluded.name_fr,
  sort_order = excluded.sort_order,
  is_active = true;

insert into public.categories (
  parent_id, name_ar, name_en, name_fr, slug, sort_order, is_active
)
select
  root.id,
  child.name_ar,
  child.name_en,
  child.name_fr,
  child.slug,
  child.sort_order,
  true
from public.categories as root
cross join (
  values
    ('كتب ومطبوعات', 'Books & Publications', 'Livres et publications', 'miscellaneous-books', 1),
    ('أجهزة مكتبية', 'Office Equipment', 'Équipement de bureau', 'miscellaneous-office-equipment', 2),
    ('أدوات ومعدات', 'Tools & Equipment', 'Outils et équipements', 'miscellaneous-tools-equipment', 3),
    ('أخرى', 'Other', 'Autres', 'miscellaneous-other', 4)
) as child(name_ar, name_en, name_fr, slug, sort_order)
where root.slug = 'miscellaneous'
on conflict (slug) do update set
  parent_id = excluded.parent_id,
  name_ar = excluded.name_ar,
  name_en = excluded.name_en,
  name_fr = excluded.name_fr,
  sort_order = excluded.sort_order,
  is_active = true;
