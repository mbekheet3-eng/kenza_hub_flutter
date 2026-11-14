-- Reordering product images must not invalidate image moderation.
-- Only actual image-row changes (insert/delete or non-order updates) reset moderation.

create or replace function public.reset_product_moderation_after_image_change()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  affected_product_id uuid;
  affected_owner_id uuid;
begin
  if tg_op = 'UPDATE'
     and old.product_id is not distinct from new.product_id
     and old.storage_path is not distinct from new.storage_path
     and old.alt_text is not distinct from new.alt_text then
    -- sort_order-only update: keep current moderation and publication state.
    return null;
  end if;

  if tg_op = 'DELETE' then
    affected_product_id := old.product_id;
  else
    affected_product_id := new.product_id;
  end if;

  select p.owner_id
    into affected_owner_id
  from public.products p
  where p.id = affected_product_id;

  -- During a product deletion cascade the parent row may no longer exist.
  if affected_owner_id is not null then
    update public.products
       set status = 'draft'
     where id = affected_product_id
       and status = 'published';

    insert into public.product_moderation (
      product_id, owner_id, status, result, reviewed_at, updated_at
    )
    values (
      affected_product_id, affected_owner_id, 'pending', null, null, now()
    )
    on conflict (product_id) do update
      set owner_id = excluded.owner_id,
          status = 'pending',
          result = null,
          reviewed_at = null,
          updated_at = now();
  end if;

  return null;
end;
$$;
