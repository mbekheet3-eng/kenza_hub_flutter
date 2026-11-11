drop policy if exists "Members and admins can update profiles" on public.profiles;
create policy "Members can update their own profile"
  on public.profiles for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));
