revoke all on function public.apply_gender_change_request() from public, anon, authenticated;

drop policy if exists "Kenza admins can manage gender change requests" on public.gender_change_requests;
drop policy if exists "Members can read own gender change requests" on public.gender_change_requests;
create policy "Members and admins can read gender change requests"
  on public.gender_change_requests for select to authenticated
  using (
    member_id = (select auth.uid())
    or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

drop policy if exists "Kenza admins can update member gender" on public.profiles;
drop policy if exists "Members can update their own profile" on public.profiles;
create policy "Members and admins can update profiles"
  on public.profiles for update to authenticated
  using (
    id = (select auth.uid())
    or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  )
  with check (
    id = (select auth.uid())
    or (select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin'
  );

drop policy if exists "Kenza admins can review gender change requests" on public.gender_change_requests;
create policy "Kenza admins can review gender change requests"
  on public.gender_change_requests for update to authenticated
  using ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((select auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create index if not exists gender_change_requests_reviewed_by_idx
  on public.gender_change_requests(reviewed_by);
