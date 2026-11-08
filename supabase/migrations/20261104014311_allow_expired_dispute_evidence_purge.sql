
create or replace function private.reject_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'DELETE'
     and current_user = 'service_role'
     and old.legal_hold = false
     and old.retention_expires_at is not null
     and old.retention_expires_at <= now()
     and exists (
       select 1 from public.disputes d
        where d.id = old.dispute_id
          and d.status in ('resolved','rejected','closed')
     )
  then
    return old;
  end if;
  raise exception 'APPEND_ONLY_RECORD';
end;
$$;

update public.dispute_evidence e
   set retention_expires_at = case
     when d.status in ('open','under_review','awaiting_response') then null
     when d.status in ('resolved','rejected','closed')
       then coalesce(e.retention_expires_at, coalesce(d.resolved_at,d.updated_at,e.created_at) + interval '60 days')
     else null
   end
  from public.disputes d
 where d.id = e.dispute_id;
