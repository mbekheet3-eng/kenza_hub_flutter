-- Harden dispute evidence uploads and administrative final decisions.
-- Participants may attach evidence only while a dispute is non-final.
-- Final decisions require a meaningful decision and an audit reason.

create or replace function private.add_dispute_evidence(
  p_dispute_id uuid,
  p_storage_path text,
  p_caption text default null
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
  if not private.is_dispute_participant(p_dispute_id) then
    raise exception 'NOT_A_DISPUTE_PARTICIPANT';
  end if;

  -- Serialize evidence registration against administrative status changes.
  select d.status
    into v_status
    from public.disputes d
   where d.id = p_dispute_id
   for update;

  if v_status is null then
    raise exception 'DISPUTE_NOT_FOUND';
  end if;

  if v_status in ('resolved', 'rejected', 'closed') then
    raise exception 'DISPUTE_FINAL_EVIDENCE_LOCKED';
  end if;

  if p_storage_path is null
     or p_storage_path !~ ('^'||p_dispute_id::text||'/'||auth.uid()::text||'/[^/]+$') then
    raise exception 'INVALID_EVIDENCE_PATH';
  end if;

  if not exists (
    select 1
      from storage.objects
     where bucket_id = 'dispute-evidence'
       and name = p_storage_path
  ) then
    raise exception 'EVIDENCE_OBJECT_NOT_FOUND';
  end if;

  insert into public.dispute_evidence(dispute_id, uploaded_by, storage_path, caption)
  values (p_dispute_id, auth.uid(), p_storage_path, nullif(trim(p_caption), ''))
  returning id into v_id;

  return v_id;
end;
$function$;

create or replace function private.admin_transition_dispute(
  p_dispute_id uuid,
  p_new_status text,
  p_decision text,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_old text;
  v_is_final boolean;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;

  if p_new_status not in ('under_review', 'awaiting_response', 'resolved', 'rejected', 'closed') then
    raise exception 'INVALID_STATUS';
  end if;

  if p_reason is null or char_length(trim(p_reason)) < 8 then
    raise exception 'AUDIT_REASON_REQUIRED';
  end if;

  v_is_final := p_new_status in ('resolved', 'rejected', 'closed');

  if v_is_final and (p_decision is null or char_length(trim(p_decision)) < 8) then
    raise exception 'FINAL_DECISION_REQUIRED';
  end if;

  select d.status
    into v_old
    from public.disputes d
   where d.id = p_dispute_id
   for update;

  if v_old is null then
    raise exception 'DISPUTE_NOT_FOUND';
  end if;

  if v_old in ('resolved', 'rejected', 'closed') then
    raise exception 'DISPUTE_FINAL';
  end if;

  update public.disputes
     set status = p_new_status,
         admin_decision = case when v_is_final then trim(p_decision) else admin_decision end,
         resolved_by = case when v_is_final then auth.uid() else resolved_by end,
         resolved_at = case when v_is_final then pg_catalog.now() else resolved_at end
   where id = p_dispute_id;

  insert into public.admin_audit_log(
    actor_user_id, action, target_table, target_id, reason, before_data, after_data
  )
  values (
    auth.uid(),
    'dispute.status_changed',
    'disputes',
    p_dispute_id,
    trim(p_reason),
    pg_catalog.jsonb_build_object('status', v_old),
    pg_catalog.jsonb_build_object(
      'status', p_new_status,
      'decision', case when v_is_final then trim(p_decision) else null end
    )
  );
end;
$function$;

-- Keep the existing authenticated/service-role wrapper permissions unchanged.
comment on function private.add_dispute_evidence(uuid, text, text) is
  'Registers dispute evidence only for an authenticated dispute participant while the dispute is non-final; locks the dispute row to serialize against closure.';
comment on function private.admin_transition_dispute(uuid, text, text, text) is
  'Admin-only dispute transition. Requires an audit reason of at least 8 characters and a decision of at least 8 characters for final statuses; records every transition in admin_audit_log.';
