-- Gemini product-image moderation and server-enforced publication gate.

create table if not exists public.product_moderation (
  id uuid primary key default gen_random_uuid(),
  product_id uuid unique references public.products(id) on delete set null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'approved', 'rejected', 'review_required')),
  result jsonb,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists product_moderation_owner_created_idx
  on public.product_moderation (owner_id, created_at desc);

alter table public.product_moderation enable row level security;
revoke all on table public.product_moderation from public, anon, authenticated;
grant all on table public.product_moderation to service_role;

create or replace function public.guard_product_publication_with_moderation()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  moderation_approved boolean := false;
  listing_content_changed boolean := false;
begin
  if tg_op = 'UPDATE' then
    listing_content_changed :=
      new.title is distinct from old.title
      or new.description is distinct from old.description
      or new.category_id is distinct from old.category_id;

    if listing_content_changed then
      if old.status = 'published' then
        new.status := 'draft';
      end if;

      insert into public.product_moderation (
        product_id, owner_id, status, result, reviewed_at, updated_at
      )
      values (
        new.id, new.owner_id, 'pending', null, null, now()
      )
      on conflict (product_id) do update
        set owner_id = excluded.owner_id,
            status = 'pending',
            result = null,
            reviewed_at = null,
            updated_at = now();
    end if;
  end if;

  if new.status = 'published' then
    select exists (
      select 1
      from public.product_moderation pm
      where pm.product_id = new.id
        and pm.status = 'approved'
    ) into moderation_approved;

    if not moderation_approved then
      raise exception 'Product images must pass server-side moderation before publication'
        using errcode = '42501';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists products_require_image_moderation on public.products;
create trigger products_require_image_moderation
before insert or update on public.products
for each row
execute function public.guard_product_publication_with_moderation();

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

drop trigger if exists product_images_reset_moderation on public.product_images;
create trigger product_images_reset_moderation
after insert or update or delete on public.product_images
for each row
execute function public.reset_product_moderation_after_image_change();
