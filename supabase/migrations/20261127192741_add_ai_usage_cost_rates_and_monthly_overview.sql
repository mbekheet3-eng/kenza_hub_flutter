
alter table public.ai_model_pricing
 add column if not exists scheduled_input_cost_per_million_usd numeric(14,8),
 add column if not exists scheduled_output_cost_per_million_usd numeric(14,8),
 add column if not exists scheduled_effective_at timestamptz;
update public.ai_model_pricing set input_cost_per_million_usd=0.75,output_cost_per_million_usd=3.75,
 scheduled_input_cost_per_million_usd=1.50,scheduled_output_cost_per_million_usd=7.50,
 scheduled_effective_at='2027-01-01 00:00:00+00',updated_at=now() where model='gemini-3.8-flash';
update public.ai_model_pricing set input_cost_per_million_usd=0.30,output_cost_per_million_usd=2.50,
 scheduled_input_cost_per_million_usd=null,scheduled_output_cost_per_million_usd=null,
 scheduled_effective_at=null,updated_at=now() where model='gemini-3.5-flash-lite';

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
   when coalesce(ip.scheduled_effective_at>now(),false) then
    (p_input_tokens::numeric*ip.input_cost_per_million_usd+p_output_tokens::numeric*ip.output_cost_per_million_usd)/1000000
   when ip.input_cost_per_million_usd is null or ip.output_cost_per_million_usd is null then null
   else (p_input_tokens::numeric*ip.input_cost_per_million_usd+p_output_tokens::numeric*ip.output_cost_per_million_usd)/1000000
  end
 from public.ai_model_pricing ip where e.user_id=v_user_id and e.service_key=p_service_key
  and e.request_id=p_request_id and e.attempt_no=p_attempt_no and ip.model=e.model;
 return found;
end;
$$;

create or replace view public.ai_usage_monthly_overview with (security_invoker=true) as
with month_usage as (
 select count(*)::bigint as gemini_attempts,count(distinct user_id)::bigint as active_users,
  coalesce(sum(input_tokens),0)::bigint as input_tokens,coalesce(sum(output_tokens),0)::bigint as output_tokens,
  sum(estimated_cost_usd) as estimated_cost_usd
 from public.ai_usage_events where consumed_at>=date_trunc('month',now() at time zone 'utc') at time zone 'utc'
), settings as (select monthly_budget_usd from public.ai_usage_settings where id=1)
select date_trunc('month',now() at time zone 'utc') as month_utc,month_usage.*,
 settings.monthly_budget_usd,
 case when settings.monthly_budget_usd is null then 'budget_not_set'
  when month_usage.estimated_cost_usd is null then 'cost_not_available'
  when month_usage.estimated_cost_usd>=settings.monthly_budget_usd*0.90 then 'alert_90_percent'
  when month_usage.estimated_cost_usd>=settings.monthly_budget_usd*0.70 then 'alert_70_percent'
  else 'within_budget' end as budget_alert_level
from month_usage cross join settings;
grant select on public.ai_usage_monthly_overview to authenticated;
