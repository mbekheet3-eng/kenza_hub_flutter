-- Member gender and product audience controls.
alter table public.profiles
  add column if not exists gender text
  check (gender in ('male', 'female'));

alter table public.products
  add column if not exists audience text not null default 'all'
  check (audience in ('all', 'men_only', 'women_only'));

create table if not exists public.gender_change_requests (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references auth.users(id) on delete cascade,
  current_gender text not null check (current_gender in ('male','female')),
  requested_gender text not null check (requested_gender in ('male','female')),
  reason text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  admin_note text,
  created_at timestamptz not null default now(),
  constraint gender_change_must_differ check (current_gender <> requested_gender)
);

create index if not exists gender_change_requests_member_created_idx
  on public.gender_change_requests(member_id, created_at desc);
create unique index if not exists gender_change_requests_one_pending_per_member
  on public.gender_change_requests(member_id) where status = 'pending';

alter table public.gender_change_requests enable row level security;

drop policy if exists "Members can submit own gender change requests" on public.gender_change_requests;
create policy "Members can submit own gender change requests"
  on public.gender_change_requests for insert to authenticated
  with check (
    member_id = (select auth.uid())
    and status = 'pending'
    and reviewed_by is null
    and reviewed_at is null
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid())
        and p.gender = current_gender
        and p.gender is not null
    )
  );

drop policy if exists "Members can read own gender change requests" on public.gender_change_requests;
create policy "Members can read own gender change requests"
  on public.gender_change_requests for select to authenticated
  using (member_id = (select auth.uid()));

drop policy if exists "Kenza admins can manage gender change requests" on public.gender_change_requests;
create policy "Kenza admins can manage gender change requests"
  on public.gender_change_requests for all to authenticated
  using ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin')
  with check ((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin');

create or replace function public.guard_profile_gender_change()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE'
     and old.gender is not null
     and new.gender is distinct from old.gender
     and coalesce((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false) = false then
    raise exception 'تغيير النوع يتطلب موافقة الإدارة'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_profile_gender_change_trigger on public.profiles;
create trigger guard_profile_gender_change_trigger
before update of gender on public.profiles
for each row execute function public.guard_profile_gender_change();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  chosen_gender text;
begin
  chosen_gender := nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'gender'), '');
  if chosen_gender is not null and chosen_gender not in ('male', 'female') then
    raise exception 'Invalid member gender';
  end if;

  insert into public.profiles (id, display_name, avatar_url, gender)
  values (
    new.id,
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(pg_catalog.btrim(new.raw_user_meta_data ->> 'avatar_url'), ''),
    chosen_gender
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop policy if exists "Visitors and owners can read products" on public.products;
create policy "Visitors and owners can read products"
  on public.products for select to anon, authenticated
  using (
    owner_id = (select auth.uid())
    or (
      status = 'published'
      and (
        audience = 'all'
        or (
          (select auth.uid()) is not null
          and exists (
            select 1 from public.profiles p
            where p.id = (select auth.uid())
              and (
                (audience = 'women_only' and p.gender = 'female')
                or (audience = 'men_only' and p.gender = 'male')
              )
          )
        )
      )
    )
  );

drop policy if exists "Members can create their own products" on public.products;
create policy "Members can create their own products"
  on public.products for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid())
        and p.gender is not null
        and (
          audience = 'all'
          or (audience = 'women_only' and p.gender = 'female')
          or (audience = 'men_only' and p.gender = 'male')
        )
    )
  );

drop policy if exists "Members can update their own products" on public.products;
create policy "Members can update their own products"
  on public.products for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (
    owner_id = (select auth.uid())
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid())
        and p.gender is not null
        and (
          audience = 'all'
          or (audience = 'women_only' and p.gender = 'female')
          or (audience = 'men_only' and p.gender = 'male')
        )
    )
  );

drop policy if exists "Buyer can start conversation with product seller" on public.conversations;
create policy "Buyer can start conversation with product seller"
  on public.conversations for insert to authenticated
  with check (
    (select auth.uid()) = buyer_id
    and buyer_id <> seller_id
    and exists (
      select 1
      from public.products p
      join public.profiles buyer on buyer.id = buyer_id
      where p.id = product_id
        and p.owner_id = seller_id
        and p.status = 'published'
        and buyer.gender is not null
        and (
          p.audience = 'all'
          or (p.audience = 'women_only' and buyer.gender = 'female')
          or (p.audience = 'men_only' and buyer.gender = 'male')
        )
    )
  );
