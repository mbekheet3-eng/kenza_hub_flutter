
create or replace function private.reject_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
declare v_old jsonb; v_new jsonb;
begin
  if tg_table_schema = 'public' and tg_table_name = 'dispute_evidence' then
    if tg_op = 'UPDATE' and current_user = 'postgres' then
      v_old := to_jsonb(old) - array['retention_expires_at','legal_hold','legal_hold_reason','legal_hold_set_at'];
      v_new := to_jsonb(new) - array['retention_expires_at','legal_hold','legal_hold_reason','legal_hold_set_at'];
      if v_old = v_new then
        return new;
      end if;
    elsif tg_op = 'DELETE' and current_user = 'service_role' then
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
  end if;
  raise exception 'APPEND_ONLY_RECORD';
end;
$$;
