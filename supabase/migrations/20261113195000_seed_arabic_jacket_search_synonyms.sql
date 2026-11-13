-- Seed initial Arabic spellings for English jacket listings.
-- Search synonyms are intentionally data-driven and can be expanded as real queries are observed.
insert into public.search_synonyms
  (canonical_term, alias_term, language_code, category_id, is_active)
values
  ('jacket', 'جاكت', 'ar', null, true),
  ('jacket', 'جاكيت', 'ar', null, true),
  ('jacket', 'جاكتات', 'ar', null, true),
  ('jacket', 'جاكيتات', 'ar', null, true),
  ('jacket', 'جواكت', 'ar', null, true)
on conflict do nothing;
