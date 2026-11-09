create index categories_parent_id_idx
  on public.categories(parent_id);

create index products_owner_id_idx
  on public.products(owner_id);

create index products_category_id_idx
  on public.products(category_id);

create index products_public_listing_idx
  on public.products(created_at desc)
  where status = 'published';

create index product_images_product_sort_idx
  on public.product_images(product_id, sort_order);

create policy "Members can read their own profile"
on public.profiles for select
to authenticated
using ((select auth.uid()) = id);

create policy "Members can create their own profile"
on public.profiles for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "Members can update their own profile"
on public.profiles for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create policy "Anyone can read active categories"
on public.categories for select
to anon, authenticated
using (is_active = true);

create policy "Visitors and owners can read products"
on public.products for select
to anon, authenticated
using (
  status = 'published'
  or owner_id = (select auth.uid())
);

create policy "Members can create their own products"
on public.products for insert
to authenticated
with check ((select auth.uid()) = owner_id);

create policy "Members can update their own products"
on public.products for update
to authenticated
using ((select auth.uid()) = owner_id)
with check ((select auth.uid()) = owner_id);

create policy "Members can delete their own products"
on public.products for delete
to authenticated
using ((select auth.uid()) = owner_id);

create policy "Visitors and owners can read product images"
on public.product_images for select
to anon, authenticated
using (
  exists (
    select 1
    from public.products p
    where p.id = product_images.product_id
      and (
        p.status = 'published'
        or p.owner_id = (select auth.uid())
      )
  )
);

create policy "Members can add images to their own products"
on public.product_images for insert
to authenticated
with check (
  exists (
    select 1
    from public.products p
    where p.id = product_images.product_id
      and p.owner_id = (select auth.uid())
  )
);

create policy "Members can update images of their own products"
on public.product_images for update
to authenticated
using (
  exists (
    select 1
    from public.products p
    where p.id = product_images.product_id
      and p.owner_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.products p
    where p.id = product_images.product_id
      and p.owner_id = (select auth.uid())
  )
);

create policy "Members can delete images of their own products"
on public.product_images for delete
to authenticated
using (
  exists (
    select 1
    from public.products p
    where p.id = product_images.product_id
      and p.owner_id = (select auth.uid())
  )
);
