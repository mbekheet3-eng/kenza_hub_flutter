-- Dispute evidence integrity, access audit, and service-only registration.
-- Applied to Supabase project kenza-hub-v2 before recording this migration.

alter table public.dispute_evidence
  add column if not exists file_sha256 text;

alter table public.dispute_evidence
  drop constraint if exists dispute_evidence_sha256_format;

alter table public.dispute_evidence
  add constraint dispute_evidence_sha256_format
  check (file_sha256 is null or file_sha256 ~ '^[0-9a-f]{64}$');

create table if not exists public.dispute_evidence_access_log (
  id uuid primary key default gen_random_uuid(),
  evidence_id uuid not null,
  dispute_id uuid not null,
  actor_user_id uuid not null,
  action text not null check (action in ('view_url_issued','download_url_issued')),
  created_at timestamptz not null default now()
);

alter table public.dispute_evidence_access_log enable row level security;

drop policy if exists dispute_evidence_access_log_admin_read
  on public.dispute_evidence_access_log;
create policy dispute_evidence_access_log_admin_read
  on public.dispute_evidence_access_log
  for select to authenticated
  using (private.is_admin());

revoke all on public.dispute_evidence_access_log from public, anon, authenticated;
grant select on public.dispute_evidence_access_log to authenticated;
grant insert on public.dispute_evidence_access_log to service_role;

create or replace function private.reject_dispute_evidence_access_log_mutation()
returns trigger
language plpgsql
set search_path = ''
as $function$
begin
  raise exception 'AUDIT_LOG_APPEND_ONLY';
end;
$function$;

drop trigger if exists dispute_evidence_access_log_append_only
  on public.dispute_evidence_access_log;
create trigger dispute_evidence_access_log_append_only
before update or delete on public.dispute_evidence_access_log
for each row execute function private.reject_dispute_evidence_access_log_mutation();

create or replace function public.register_dispute_evidence_with_hash(
  p_dispute_id uuid,
  p_storage_path text,
  p_caption text,
  p_sha256 text,
  p_actor_user_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_id uuid;
  v_status text;
begin
  if p_actor_user_id is null
     or not exists (
       select 1 from auth.users u
       where u.id = p_actor_user_id and u.deleted_at is null
     )
     or not exists (
       select 1
       from public.disputes d
       join public.orders o on o.id = d.order_id
       left join public.seller_profiles sp on sp.id = o.seller_profile_id
       where d.id = p_dispute_id
         and (o.buyer_id = p_actor_user_id or sp.owner_user_id = p_actor_user_id)
     ) then
    raise exception 'NOT_A_DISPUTE_PARTICIPANT';
  end if;

  if p_sha256 is null or p_sha256 !~ '^[0-9a-f]{64}$' then
    raise exception 'INVALID_EVIDENCE_HASH';
  end if;

  select d.status into v_status
  from public.disputes d
  where d.id = p_dispute_id
  for update;

  if v_status is null then raise exception 'DISPUTE_NOT_FOUND'; end if;
  if v_status in ('resolved', 'rejected', 'closed') then
    raise exception 'DISPUTE_FINAL_EVIDENCE_LOCKED';
  end if;

  if p_storage_path is null
     or p_storage_path !~ ('^' || p_dispute_id::text || '/' ||
                           p_actor_user_id::text || '/[^/]+$') then
    raise exception 'INVALID_EVIDENCE_PATH';
  end if;

  if not exists (
    select 1 from storage.objects
    where bucket_id = 'dispute-evidence' and name = p_storage_path
  ) then
    raise exception 'EVIDENCE_OBJECT_NOT_FOUND';
  end if;

  insert into public.dispute_evidence(
    dispute_id, uploaded_by, storage_path, caption, file_sha256
  )
  values (
    p_dispute_id, p_actor_user_id, p_storage_path,
    nullif(trim(p_caption), ''), p_sha256
  )
  returning id into v_id;

  return v_id;
end;
$function$;

revoke all on function public.register_dispute_evidence_with_hash(
  uuid, text, text, text, uuid
) from public, anon, authenticated;
grant execute on function public.register_dispute_evidence_with_hash(
  uuid, text, text, text, uuid
) to service_role;

revoke all on function private.add_dispute_evidence(uuid, text, text)
  from public, anon, authenticated;

drop policy if exists dispute_evidence_object_read on storage.objects;
drop policy if exists dispute_evidence_object_admin_read on storage.objects;
