
create or replace function public.finish_ai_usage_attempt(
 p_service_key text,p_request_id uuid,p_attempt_no integer,p_http_status integer,p_succeeded boolean,
 p_input_tokens bigint default null,p_output_tokens bigint default null
) returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare v_user_id uuid := auth.uid();
begin
 if v_user_id is null then raise exception 'Authentication required' using errcode='28000'; end if;
 update public.ai_usage_events e set finished_at=now(),provider_http_status=p_http_status,succeeded=p_succeeded,
  input_tokens=case when p_input_tokens is null then null else greatest(0,p_input_tokens) end,
  output_tokens=case when p_output_tokens is null then null else greatest(0,p_output_tokens) end,
  estimated_cost_usd=case
   when p_input_tokens is null or p_output_tokens is null then null
   when ip.scheduled_effective_at is not null and ip.scheduled_effective_at<=now()
    and ip.scheduled_input_cost_per_million_usd is not null and ip.scheduled_output_cost_per_million_usd is not null
    then (p_input_tokens::numeric*ip.scheduled_input_cost_per_million_usd
      +p_output_tokens::numeric*ip.scheduled_output_cost_per_million_usd)/1000000
   when ip.input_cost_per_million_usd is null or ip.output_cost_per_million_usd is null then null
   else (p_input_tokens::numeric*ip.input_cost_per_million_usd
      +p_output_tokens::numeric*ip.output_cost_per_million_usd)/1000000 end
 from public.ai_model_pricing ip where e.user_id=v_user_id and e.service_key=p_service_key
  and e.request_id=p_request_id and e.attempt_no=p_attempt_no and ip.model=e.model;
 return found;
end;
$$;
