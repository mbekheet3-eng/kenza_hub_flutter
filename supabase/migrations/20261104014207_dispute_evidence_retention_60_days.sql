
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

alter table public.dispute_evidence
  add column if not exists retention_expires_at timestamptz,
  add column if not exists legal_hold boolean not null default false,
  add column if not exists legal_hold_reason text,
  add column if not exists legal_hold_set_at timestamptz;

create index if not exists dispute_evidence_retention_idx
  on public.dispute_evidence (retention_expires_at)
  where retention_expires_at is not null and legal_hold = false;

create or replace function private.sync_dispute_evidence_retention()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status in ('open','under_review','awaiting_response') then
    update public.dispute_evidence
       set retention_expires_at = null
     where dispute_id = new.id;
  elsif new.status in ('resolved','rejected','closed') then
    update public.dispute_evidence
       set retention_expires_at = coalesce(retention_expires_at, now() + interval '60 days')
     where dispute_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists disputes_evidence_retention on public.disputes;
create trigger disputes_evidence_retention
after update of status on public.disputes
for each row
when (old.status is distinct from new.status)
execute function private.sync_dispute_evidence_retention();

create or replace function private.initialize_dispute_evidence_retention()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_status text;
begin
  select status into v_status from public.disputes where id = new.dispute_id;
  if v_status in ('open','under_review','awaiting_response') then
    new.retention_expires_at := null;
  elsif v_status in ('resolved','rejected','closed') then
    new.retention_expires_at := coalesce(new.retention_expires_at, now() + interval '60 days');
  end if;
  return new;
end;
$$;

drop trigger if exists dispute_evidence_retention_init on public.dispute_evidence;
create trigger dispute_evidence_retention_init
before insert on public.dispute_evidence
for each row
execute function private.initialize_dispute_evidence_retention();

create or replace function private.set_dispute_evidence_legal_hold(
  p_evidence_id uuid,
  p_hold boolean,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_before jsonb; v_dispute_id uuid; v_status text;
begin
  if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
  if p_hold and (p_reason is null or char_length(trim(p_reason)) < 8) then
    raise exception 'LEGAL_HOLD_REASON_REQUIRED';
  end if;

  select to_jsonb(e), e.dispute_id into v_before, v_dispute_id
    from public.dispute_evidence e
   where e.id = p_evidence_id
   for update;
  if v_dispute_id is null then raise exception 'EVIDENCE_NOT_FOUND'; end if;

  select status into v_status from public.disputes where id = v_dispute_id;

  update public.dispute_evidence
     set legal_hold = p_hold,
         legal_hold_reason = case when p_hold then trim(p_reason) else null end,
         legal_hold_set_at = case when p_hold then now() else null end,
         retention_expires_at = case
           when p_hold then null
           when v_status in ('resolved','rejected','closed') then now() + interval '60 days'
           else null
         end
   where id = p_evidence_id;

  insert into public.admin_audit_log(actor_user_id, action, target_table, target_id, reason, before_data, after_data)
  values(auth.uid(),
         case when p_hold then 'dispute_evidence.legal_hold_set' else 'dispute_evidence.legal_hold_released' end,
         'dispute_evidence', p_evidence_id, coalesce(nullif(trim(p_reason),''),'Legal hold released'),
         v_before,
         jsonb_build_object('legal_hold',p_hold,'legal_hold_reason',case when p_hold then trim(p_reason) else null end));
end;
$$;

revoke all on function private.set_dispute_evidence_legal_hold(uuid,boolean,text) from public, anon;
grant execute on function private.set_dispute_evidence_legal_hold(uuid,boolean,text) to authenticated;

create or replace function public.set_dispute_evidence_legal_hold(
  p_evidence_id uuid,
  p_hold boolean,
  p_reason text
)
returns void
language sql
security invoker
set search_path = ''
as $$ select private.set_dispute_evidence_legal_hold($1,$2,$3) $$;

revoke all on function public.set_dispute_evidence_legal_hold(uuid,boolean,text) from public, anon;
grant execute on function public.set_dispute_evidence_legal_hold(uuid,boolean,text) to authenticated;

create or replace function public.verify_dispute_retention_cron_secret(p_secret text)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare v_secret text;
begin
  select decrypted_secret into v_secret
    from vault.decrypted_secrets
   where name = 'dispute_evidence_retention_cron_secret';
  return v_secret is not null and p_secret is not null and p_secret = v_secret;
end;
$$;

revoke all on function public.verify_dispute_retention_cron_secret(text) from public, anon, authenticated;
grant execute on function public.verify_dispute_retention_cron_secret(text) to service_role;

select vault.create_secret('https://klkcroynomxuajggqqqx.supabase.co','kenza_project_url','Kenza Hub v2 project URL');
select vault.create_secret('sb_publishable_tKDfwczxGzGn44JNVLqI6Q_WewP1YYy','kenza_publishable_key','Kenza Hub v2 publishable key');
select vault.create_secret(encode(extensions.gen_random_bytes(32),'hex'),'dispute_evidence_retention_cron_secret','Internal token for scheduled dispute evidence cleanup');

select cron.schedule(
  'delivery-details-retention-daily',
  '10 3 * * *',
  $$select private.purge_expired_delivery_details();$$
);
