-- Add French as a first-class category language.
-- Keep category IDs and slugs unchanged; future categories must provide all three names.

alter table public.categories
  add column name_fr text;

update public.categories
set name_fr = case slug
  when 'clothes' then 'Vêtements'
  when 'shoes' then 'Chaussures'
  when 'children-supplies' then 'Articles pour enfants'
  when 'home-supplies' then 'Articles pour la maison'
  else null
end;

do $$
begin
  if exists (
    select 1
    from public.categories
    where name_fr is null or btrim(name_fr) = ''
  ) then
    raise exception 'Every existing category must have a French name before enabling required translations';
  end if;
end;
$$;

alter table public.categories
  alter column name_fr set not null;

alter table public.categories
  add constraint categories_name_fr_not_blank
  check (btrim(name_fr) <> '');
