
create or replace function private.reject_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
declare v_old jsonb;
begin
  if tg_op = 'DELETE' and tg_table_schema = 'public' and tg_table_name = 'dispute_evidence'
     and current_user = 'service_role'
  then
    v_old := to_jsonb(old);
    if coalesce((v_old ->> 'legal_hold')::boolean, false) = false
       and nullif(v_old ->> 'retention_expires_at','') is not null
       and (v_old ->> 'retention_expires_at')::timestamptz <= now()
       and exists (
         select 1 from public.disputes d
          where d.id = (v_old ->> 'dispute_id')::uuid
            and d.status in ('resolved','rejected','closed')
       )
    then
      return old;
    end if;
  end if;
  raise exception 'APPEND_ONLY_RECORD';
end;
$$;
