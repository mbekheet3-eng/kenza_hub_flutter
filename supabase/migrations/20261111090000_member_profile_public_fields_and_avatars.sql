create table if not exists public.member_public_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  first_name text not null default 'عضو كنزة هب',
  avatar_url text,
  updated_at timestamptz not null default now()
);

alter table public.member_public_profiles enable row level security;
revoke all on public.member_public_profiles from public, anon, authenticated;
grant select on public.member_public_profiles to anon, authenticated;

drop policy if exists "Public member profiles are readable by everyone" on public.member_public_profiles;
create policy "Public member profiles are readable by everyone"
on public.member_public_profiles
for select
to anon, authenticated
using (true);

create or replace function public.sync_member_public_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_name text;
begin
  normalized_name := pg_catalog.regexp_replace(
    pg_catalog.btrim(coalesce(new.display_name, '')),
    '[[:space:]]+',
    ' ',
    'g'
  );

  insert into public.member_public_profiles (id, first_name, avatar_url, updated_at)
  values (
    new.id,
    coalesce(nullif(pg_catalog.split_part(normalized_name, ' ', 1), ''), 'عضو كنزة هب'),
    new.avatar_url,
    now()
  )
  on conflict (id) do update
  set first_name = excluded.first_name,
      avatar_url = excluded.avatar_url,
      updated_at = now();

  return new;
end;
$$;

revoke all on function public.sync_member_public_profile() from public;
revoke execute on function public.sync_member_public_profile() from anon, authenticated;

drop trigger if exists sync_member_public_profile_after_profile_change on public.profiles;
create trigger sync_member_public_profile_after_profile_change
after insert or update of display_name, avatar_url
on public.profiles
for each row
execute function public.sync_member_public_profile();

insert into public.member_public_profiles (id, first_name, avatar_url)
select
  p.id,
  coalesce(
    nullif(
      pg_catalog.split_part(
        pg_catalog.regexp_replace(
          pg_catalog.btrim(coalesce(p.display_name, '')),
          '[[:space:]]+',
          ' ',
          'g'
        ),
        ' ',
        1
      ),
      ''
    ),
    'عضو كنزة هب'
  ),
  p.avatar_url
from public.profiles p
on conflict (id) do update
set first_name = excluded.first_name,
    avatar_url = excluded.avatar_url,
    updated_at = now();

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('member-avatars', 'member-avatars', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Members can upload their own avatar files" on storage.objects;
create policy "Members can upload their own avatar files"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'member-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Members can update their own avatar files" on storage.objects;
create policy "Members can update their own avatar files"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'member-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
)
with check (
  bucket_id = 'member-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

drop policy if exists "Members can delete their own avatar files" on storage.objects;
create policy "Members can delete their own avatar files"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'member-avatars'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);
