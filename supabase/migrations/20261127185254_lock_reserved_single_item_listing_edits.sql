create or replace function public.guard_product_publication_with_moderation()
returns trigger
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $function$
declare
  moderation_approved boolean := false;
  listing_content_changed boolean := false;
begin
  if tg_op = 'UPDATE' then
    listing_content_changed :=
      new.title is distinct from old.title
      or new.description is distinct from old.description
      or new.category_id is distinct from old.category_id
      or new.price is distinct from old.price
      or new.currency is distinct from old.currency
      or new.audience is distinct from old.audience
      or new.custom_category_name is distinct from old.custom_category_name
      or new.has_variants is distinct from old.has_variants;

    if old.reserved_by_order_id is not null
       and new.reserved_by_order_id is not null
       and (listing_content_changed or new.status is distinct from old.status) then
      raise exception 'This listing is reserved by an accepted order and cannot be edited until the reservation ends'
        using errcode = '23514';
    end if;

    if listing_content_changed then
      if old.status = 'published' then new.status := 'draft'; end if;
      insert into public.product_moderation (product_id, owner_id, status, result, reviewed_at, updated_at)
      values (new.id, new.owner_id, 'pending', null, null, now())
      on conflict (product_id) do update
        set owner_id = excluded.owner_id, status = 'pending', result = null,
            reviewed_at = null, updated_at = now();
    end if;

    if new.status = 'published' and old.status = 'archived'
       and old.reserved_by_order_id is not null and new.reserved_by_order_id is null then
      return new;
    end if;
  end if;

  if new.status = 'published' then
    select exists (select 1 from public.product_moderation pm
      where pm.product_id = new.id and pm.status = 'approved') into moderation_approved;
    if not moderation_approved then
      raise exception 'Product images must pass server-side moderation before publication' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$function$;