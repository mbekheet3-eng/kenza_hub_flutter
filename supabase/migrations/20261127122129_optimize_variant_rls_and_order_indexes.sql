-- Separate write policies from public read policy and index the order variant FK.
drop policy if exists "pro seller owner manages variants" on public.product_variants;
create policy "pro seller owner inserts variants" on public.product_variants for insert to authenticated with check (
 exists(select 1 from public.products p where p.id=product_id and p.owner_id=(select auth.uid()))
 and exists(select 1 from public.account_roles r where r.user_id=(select auth.uid()) and r.role='pro_seller' and r.is_active)
);
create policy "pro seller owner updates variants" on public.product_variants for update to authenticated using (
 exists(select 1 from public.products p where p.id=product_id and p.owner_id=(select auth.uid()))
 and exists(select 1 from public.account_roles r where r.user_id=(select auth.uid()) and r.role='pro_seller' and r.is_active)
) with check (
 exists(select 1 from public.products p where p.id=product_id and p.owner_id=(select auth.uid()))
 and exists(select 1 from public.account_roles r where r.user_id=(select auth.uid()) and r.role='pro_seller' and r.is_active)
);
create policy "pro seller owner deletes variants" on public.product_variants for delete to authenticated using (
 exists(select 1 from public.products p where p.id=product_id and p.owner_id=(select auth.uid()))
 and exists(select 1 from public.account_roles r where r.user_id=(select auth.uid()) and r.role='pro_seller' and r.is_active)
);
create index if not exists product_orders_variant_product_idx on public.product_orders(variant_id,product_id);
