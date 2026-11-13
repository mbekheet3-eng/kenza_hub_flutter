create extension if not exists pg_trgm with schema extensions;

create or replace function public.normalize_search_text(p_text text)
returns text language sql immutable parallel safe set search_path = ''
as $$
 select pg_catalog.btrim(pg_catalog.regexp_replace(
  pg_catalog.regexp_replace(
   pg_catalog.translate(
    pg_catalog.translate(pg_catalog.lower(coalesce(p_text,'')), 'أإآٱىةـ', 'اااايه'),
    'àáâäãåāăąèéêëēėęěìíîïīòóôöõøōùúûüūýÿçćčñńňśšşžźż',
    'aaaaaaaaaeeeeeeeeiiiiiooooooouuuuuyycccnnnssszzz'
   ),
   U&'[\064B-\065F\0670]', '', 'g'
  ),
  '[[:space:]]+', ' ', 'g'
 ));
$$;

alter table public.products
 add column if not exists search_title_normalized text generated always as (public.normalize_search_text(title)) stored,
 add column if not exists search_description_normalized text generated always as (public.normalize_search_text(coalesce(description,''))) stored,
 add column if not exists search_custom_category_normalized text generated always as (public.normalize_search_text(coalesce(custom_category_name,''))) stored;

alter table public.categories
 add column if not exists search_name_ar_normalized text generated always as (public.normalize_search_text(name_ar)) stored,
 add column if not exists search_name_en_normalized text generated always as (public.normalize_search_text(name_en)) stored,
 add column if not exists search_name_fr_normalized text generated always as (public.normalize_search_text(name_fr)) stored;

create table if not exists public.search_synonyms (
 id uuid primary key default gen_random_uuid(),
 canonical_term text not null,
 alias_term text not null,
 language_code text not null check (language_code in ('ar','en','fr')),
 category_id uuid references public.categories(id) on delete cascade,
 is_active boolean not null default true,
 created_at timestamptz not null default now(),
 normalized_canonical text generated always as (public.normalize_search_text(canonical_term)) stored,
 normalized_alias text generated always as (public.normalize_search_text(alias_term)) stored,
 constraint search_synonyms_canonical_length check (char_length(btrim(canonical_term)) between 2 and 100),
 constraint search_synonyms_alias_length check (char_length(btrim(alias_term)) between 2 and 100),
 constraint search_synonyms_not_identical check (normalized_canonical <> normalized_alias)
);

create unique index if not exists search_synonyms_alias_unique_idx on public.search_synonyms
 (language_code, normalized_alias, (coalesce(category_id, '00000000-0000-0000-0000-000000000000'::uuid)));
create index if not exists search_synonyms_alias_trgm_idx on public.search_synonyms using gin (normalized_alias extensions.gin_trgm_ops) where is_active;

alter table public.search_synonyms enable row level security;
drop policy if exists "Active search synonyms are readable" on public.search_synonyms;
create policy "Active search synonyms are readable" on public.search_synonyms for select to anon, authenticated using (is_active);
drop policy if exists "Admins manage search synonyms" on public.search_synonyms;
create policy "Admins manage search synonyms" on public.search_synonyms for all to authenticated
 using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
 with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

grant select on public.search_synonyms to anon, authenticated;
grant insert, update, delete on public.search_synonyms to authenticated;

create index if not exists products_search_title_trgm_idx on public.products using gin (search_title_normalized extensions.gin_trgm_ops) where status='published';
create index if not exists products_search_description_trgm_idx on public.products using gin (search_description_normalized extensions.gin_trgm_ops) where status='published';
create index if not exists products_search_custom_category_trgm_idx on public.products using gin (search_custom_category_normalized extensions.gin_trgm_ops) where status='published';
create index if not exists products_public_price_idx on public.products(price) where status='published';
create index if not exists products_public_category_price_idx on public.products(category_id,price) where status='published';
create index if not exists categories_search_name_ar_trgm_idx on public.categories using gin (search_name_ar_normalized extensions.gin_trgm_ops) where is_active;
create index if not exists categories_search_name_en_trgm_idx on public.categories using gin (search_name_en_normalized extensions.gin_trgm_ops) where is_active;
create index if not exists categories_search_name_fr_trgm_idx on public.categories using gin (search_name_fr_normalized extensions.gin_trgm_ops) where is_active;

create or replace function public.search_products(
 search_query text default '', p_category_id uuid default null,
 p_min_price numeric default null, p_max_price numeric default null,
 p_sort text default 'relevance', p_limit integer default 20, p_offset integer default 0
) returns jsonb language plpgsql stable security invoker set search_path = ''
as $$
declare
 v_query text; v_terms text[] := array[]::text[]; v_expanded_terms text[] := array[]::text[];
 v_sort text; v_limit integer; v_offset integer; v_total_count bigint := 0; v_items jsonb := '[]'::jsonb;
begin
 v_query := left(public.normalize_search_text(coalesce(search_query,'')),120);
 v_query := replace(replace(replace(v_query,E'\\',''),'%',''),'_','');
 if v_query <> '' then
  select coalesce(array_agg(distinct token),array[]::text[]) into v_terms
  from pg_catalog.unnest(pg_catalog.regexp_split_to_array(v_query,'[[:space:]]+')) as tokens(token)
  where char_length(token)>=2;
 end if;
 select coalesce(array_agg(distinct term),v_terms) into v_expanded_terms
 from (
  select tokens.token as term from pg_catalog.unnest(v_terms) as tokens(token)
  union all
  select s.normalized_canonical from public.search_synonyms s
   where s.is_active and s.normalized_alias=any(v_terms)
    and (s.category_id is null or s.category_id=p_category_id)
  union all
  select s.normalized_alias from public.search_synonyms s
   where s.is_active and s.normalized_canonical=any(v_terms)
    and (s.category_id is null or s.category_id=p_category_id)
 ) expanded;
 v_sort := case when p_sort in ('relevance','newest','price_low','price_high') then p_sort else 'relevance' end;
 v_limit := greatest(1,least(coalesce(p_limit,20),50));
 v_offset := greatest(0,least(coalesce(p_offset,0),100000));
 with recursive category_scope(id) as (
  select c.id from public.categories c where c.id=p_category_id and c.is_active
  union all
  select child.id from public.categories child join category_scope parent on child.parent_id=parent.id where child.is_active
 ),
 matched as (
  select p.id,p.price,p.created_at,
   (
    case when v_query<>'' and p.search_title_normalized=v_query then 10000
         when v_query<>'' and p.search_title_normalized like v_query||'%' then 8000
         when v_query<>'' and p.search_title_normalized like '%'||v_query||'%' then 6000 else 0 end
    + case when v_query<>'' and p.search_custom_category_normalized=v_query then 5800
           when v_query<>'' and p.search_custom_category_normalized like v_query||'%' then 4600
           when v_query<>'' and p.search_custom_category_normalized like '%'||v_query||'%' then 3600 else 0 end
    + case when v_query<>'' and (c.search_name_ar_normalized=v_query or c.search_name_en_normalized=v_query or c.search_name_fr_normalized=v_query) then 4200
           when v_query<>'' and (c.search_name_ar_normalized like '%'||v_query||'%' or c.search_name_en_normalized like '%'||v_query||'%' or c.search_name_fr_normalized like '%'||v_query||'%') then 3000 else 0 end
    + case when v_query<>'' and p.search_description_normalized like '%'||v_query||'%' then 1200 else 0 end
    + coalesce((select count(*)*40 from pg_catalog.unnest(v_expanded_terms) as terms(term) where p.search_title_normalized like '%'||term||'%'),0)
    + coalesce((select count(*)*32 from pg_catalog.unnest(v_expanded_terms) as terms(term) where p.search_custom_category_normalized like '%'||term||'%'),0)
    + coalesce((select count(*)*24 from pg_catalog.unnest(v_expanded_terms) as terms(term) where c.search_name_ar_normalized like '%'||term||'%' or c.search_name_en_normalized like '%'||term||'%' or c.search_name_fr_normalized like '%'||term||'%'),0)
    + coalesce((select count(*)*10 from pg_catalog.unnest(v_expanded_terms) as terms(term) where p.search_description_normalized like '%'||term||'%'),0)
   )::numeric as relevance_score
  from public.products p left join public.categories c on c.id=p.category_id
  where p.status='published'
   and (p_category_id is null or p.category_id in (select id from category_scope))
   and (p_min_price is null or p.price>=p_min_price)
   and (p_max_price is null or p.price<=p_max_price)
   and (v_query='' or p.search_title_normalized like '%'||v_query||'%'
    or p.search_custom_category_normalized like '%'||v_query||'%'
    or p.search_description_normalized like '%'||v_query||'%'
    or c.search_name_ar_normalized like '%'||v_query||'%'
    or c.search_name_en_normalized like '%'||v_query||'%'
    or c.search_name_fr_normalized like '%'||v_query||'%'
    or exists (select 1 from pg_catalog.unnest(v_expanded_terms) as terms(term)
     where p.search_title_normalized like '%'||term||'%'
      or p.search_custom_category_normalized like '%'||term||'%'
      or p.search_description_normalized like '%'||term||'%'
      or c.search_name_ar_normalized like '%'||term||'%'
      or c.search_name_en_normalized like '%'||term||'%'
      or c.search_name_fr_normalized like '%'||term||'%'))
 ),
 counted as (select count(*)::bigint as total_count from matched),
 ordered as (
  select m.*,row_number() over(order by
   case when v_sort='relevance' then m.relevance_score end desc nulls last,
   case when v_sort='newest' then m.created_at end desc nulls last,
   case when v_sort='price_low' then m.price end asc nulls last,
   case when v_sort='price_high' then m.price end desc nulls last,
   m.created_at desc,m.id) as row_number
  from matched m
 ),
 page as (select * from ordered where row_number>v_offset and row_number<=v_offset+v_limit)
 select counted.total_count,
  coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('id',page.id,'score',page.relevance_score) order by page.row_number) from page),'[]'::jsonb)
 into v_total_count,v_items from counted;
 return pg_catalog.jsonb_build_object('items',v_items,'total_count',v_total_count,'has_more',v_total_count>(v_offset+v_limit),'limit',v_limit,'offset',v_offset);
end;
$$;

revoke all on function public.search_products(text,uuid,numeric,numeric,text,integer,integer) from public;
grant execute on function public.search_products(text,uuid,numeric,numeric,text,integer,integer) to anon,authenticated;