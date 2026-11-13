grant select on public.profiles to anon;

drop policy if exists "Admins manage search synonyms" on public.search_synonyms;

create policy "Admins insert search synonyms"
 on public.search_synonyms for insert to authenticated
 with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Admins update search synonyms"
 on public.search_synonyms for update to authenticated
 using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin')
 with check (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create policy "Admins delete search synonyms"
 on public.search_synonyms for delete to authenticated
 using (((select auth.jwt()) -> 'app_metadata' ->> 'role') = 'admin');

create index if not exists search_synonyms_category_id_idx
 on public.search_synonyms(category_id);