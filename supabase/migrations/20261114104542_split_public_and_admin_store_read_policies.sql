drop policy if exists "Active stores public and owners or admins can read all" on public.stores;
create policy "Public can read active stores" on public.stores for select to anon,authenticated using(status='active');
create policy "Owners and admins can read all stores" on public.stores for select to authenticated using(owner_id=(select auth.uid()) or public.is_kenza_admin());
