-- Route existing admin-only policies through the protected Kenza admin registry.
drop policy if exists "Kenza admins can review gender change requests" on public.gender_change_requests;
create policy "Kenza admins can review gender change requests" on public.gender_change_requests for update to authenticated
using(public.is_kenza_admin()) with check(public.is_kenza_admin());
drop policy if exists "Members and admins can read gender change requests" on public.gender_change_requests;
create policy "Members and admins can read gender change requests" on public.gender_change_requests for select to authenticated
using(member_id=(select auth.uid()) or public.is_kenza_admin());

drop policy if exists "Admins delete search synonyms" on public.search_synonyms;
create policy "Admins delete search synonyms" on public.search_synonyms for delete to authenticated using(public.is_kenza_admin());
drop policy if exists "Admins insert search synonyms" on public.search_synonyms;
create policy "Admins insert search synonyms" on public.search_synonyms for insert to authenticated with check(public.is_kenza_admin());
drop policy if exists "Admins update search synonyms" on public.search_synonyms;
create policy "Admins update search synonyms" on public.search_synonyms for update to authenticated using(public.is_kenza_admin()) with check(public.is_kenza_admin());

drop policy if exists "Admins can moderate seller reviews" on public.seller_reviews;
create policy "Admins can moderate seller reviews" on public.seller_reviews for update to authenticated using(public.is_kenza_admin()) with check(public.is_kenza_admin());
drop policy if exists "Review participants and admins can read review records" on public.seller_reviews;
create policy "Review participants and admins can read review records" on public.seller_reviews for select to authenticated
using(buyer_id=(select auth.uid()) or seller_id=(select auth.uid()) or public.is_kenza_admin());

drop policy if exists "Admins can review verification requests" on public.seller_verifications;
create policy "Admins can review verification requests" on public.seller_verifications for update to authenticated
using(public.is_kenza_admin())
with check(public.is_kenza_admin() and reviewed_by=(select auth.uid()) and reviewed_at is not null and status in ('verified','rejected','revoked'));
drop policy if exists "Members and admins can read verification requests" on public.seller_verifications;
create policy "Members and admins can read verification requests" on public.seller_verifications for select to authenticated
using(seller_id=(select auth.uid()) or public.is_kenza_admin());
