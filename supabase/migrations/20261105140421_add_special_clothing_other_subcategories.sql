-- Add clear destinations under Clothes > Other.
insert into public.categories (parent_id, name_ar, name_en, slug, display_order, is_active)
select parent.id, v.name_ar, v.name_en, v.slug, v.display_order, true
from public.categories parent
cross join (values
  ('ملابس موحدة', 'Uniforms', 'clothes-other-uniforms', 1),
  ('ملابس عمل ومهن', 'Workwear', 'clothes-other-workwear', 2),
  ('ملابس تنكرية', 'Costumes', 'clothes-other-costumes', 3),
  ('ملابس مناسبات خاصة', 'Special Occasion Wear', 'clothes-other-special-occasion', 4)
) as v(name_ar, name_en, slug, display_order)
where parent.slug = 'clothes-other'
  and parent.is_active
  and not exists (select 1 from public.categories c where c.slug = v.slug);
