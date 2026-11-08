create or replace function private.admin_transition_dispute(
  p_dispute_id uuid,
  p_new_status text,
  p_decision text,
  p_reason text
)
returns void
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_old text;
  v_is_final boolean;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;

  if p_new_status is null
     or p_new_status not in ('under_review', 'awaiting_response', 'resolved', 'rejected', 'closed') then
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