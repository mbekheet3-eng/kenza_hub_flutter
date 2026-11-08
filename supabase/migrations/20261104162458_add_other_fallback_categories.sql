insert into public.categories (
  parent_id,
  name_ar,
  name_en,
  slug,
  is_active,
  display_order
)
select
  parent.id,
  'أخرى',
  'Other',
  parent.slug || '-other',
  true,
  coalesce((
    select max(child.display_order) + 1
    from public.categories child
    where child.parent_id = parent.id
  ), 1)
from public.categories parent
where parent.is_active = true
  and exists (
    select 1
    from public.categories existing_child
    where existing_child.parent_id = parent.id
      and existing_child.is_active = true
  )
on conflict (slug) do nothing;
