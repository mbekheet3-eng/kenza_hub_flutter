
-- Cover every foreign key with a leading index where one does not already exist.
do $$
declare r record; idx_name text;
begin
  for r in
    select con.conrelid::regclass as tbl,
           con.conname,
           array_agg(att.attname order by key_col.ordinality) as cols
    from pg_constraint con
    cross join lateral unnest(con.conkey) with ordinality as key_col(attnum,ordinality)
    join pg_attribute att on att.attrelid=con.conrelid and att.attnum=key_col.attnum
    where con.contype='f' and con.connamespace='public'::regnamespace
    group by con.conrelid,con.conname
  loop
    if not exists (
      select 1 from pg_index i
      where i.indrelid=r.tbl
        and (select array_agg(a.attname order by k.ord)
             from unnest(i.indkey) with ordinality k(attnum,ord)
             join pg_attribute a on a.attrelid=i.indrelid and a.attnum=k.attnum
             where k.ord <= cardinality(r.cols)) = r.cols
    ) then
      idx_name := left(replace(r.conname,'_fkey','') || '_fk_idx', 63);
      execute format('create index if not exists %I on %s (%s)',
        idx_name,r.tbl,(select string_agg(format('%I',x),', ') from unnest(r.cols) x));
    end if;
  end loop;
end $$;

drop policy if exists products_public_or_owner_read on public.products;
create policy products_public_or_owner_read on public.products for select to anon,authenticated using (
  (moderation_status = 'approved' and audience = 'public')
  or ((select auth.uid()) is not null and private.has_seller_permission(seller_id,'products:read'))
  or ((select auth.uid()) is not null and private.is_admin())
);
drop policy if exists product_images_read on public.product_images;
create policy product_images_read on public.product_images for select to anon,authenticated using (
  exists(select 1 from public.products p where p.id = product_id and (
    (p.moderation_status='approved' and p.audience='public')
    or ((select auth.uid()) is not null and private.has_seller_permission(p.seller_id,'products:read'))
  ))
);
