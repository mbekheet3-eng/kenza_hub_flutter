
create table if not exists public.ai_usage_limits (
  service_key text primary key check (service_key in ('product_suggestions','image_review','image_search')),
  individual_daily_limit integer not null default 25 check (individual_daily_limit between 1 and 10000),
  pro_seller_daily_limit integer not null default 50 check (pro_seller_daily_limit between 1 and 20000),
  requests_per_minute integer not null default 3 check (requests_per_minute between 1 and 60),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null
);
insert into public.ai_usage_limits(service_key,individual_daily_limit,pro_seller_daily_limit,requests_per_minute)
values ('product_suggestions',25,50,3),('image_review',25,50,3),('image_search',25,50,3)
on conflict (service_key) do update set
 individual_daily_limit=excluded.individual_daily_limit,
 pro_seller_daily_limit=excluded.pro_seller_daily_limit,
 requests_per_minute=excluded.requests_per_minute;

create table if not exists public.ai_model_pricing (
  model text primary key,
  input_cost_per_million_usd numeric(14,8),
  output_cost_per_million_usd numeric(14,8),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  constraint ai_model_pricing_nonnegative check (
    (input_cost_per_million_usd is null or input_cost_per_million_usd >= 0)
    and (output_cost_per_million_usd is null or output_cost_per_million_usd >= 0)
  )
);
insert into public.ai_model_pricing(model)
values ('gemini-3.8-flash'),('gemini-3.5-flash-lite')
on conflict (model) do nothing;

create table if not exists public.ai_usage_settings (
  id smallint primary key default 1 check (id=1),
  monthly_budget_usd numeric(12,2),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  constraint ai_usage_settings_budget_nonnegative check (monthly_budget_usd is null or monthly_budget_usd >= 0)
);
insert into public.ai_usage_settings(id,monthly_budget_usd) values (1,null)
on conflict (id) do nothing;

create table if not exists public.ai_usage_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  service_key text not null check (service_key in ('product_suggestions','image_review','image_search')),
  request_id uuid not null,
  attempt_no smallint not null check (attempt_no between 1 and 20),
  model text not null check (model in ('gemini-3.8-flash','gemini-3.5-flash-lite')),
  tier text not null check (tier in ('individual','pro_seller')),
  consumed_at timestamptz not null default now(),
  finished_at timestamptz,
  provider_http_status integer,
  succeeded boolean,
  input_tokens bigint,
  output_tokens bigint,
  estimated_cost_usd numeric(14,8),
  unique(user_id,service_key,request_id,attempt_no),
  constraint ai_usage_events_tokens_nonnegative check (
    (input_tokens is null or input_tokens >= 0)
    and (output_tokens is null or output_tokens >= 0)
  )
);
create index if not exists ai_usage_events_user_service_day_idx
  on public.ai_usage_events(user_id,service_key,consumed_at desc);
create index if not exists ai_usage_events_consumed_at_idx
  on public.ai_usage_events(consumed_at desc);

alter table public.ai_usage_limits enable row level security;
alter table public.ai_model_pricing enable row level security;
alter table public.ai_usage_settings enable row level security;
alter table public.ai_usage_events enable row level security;

create policy "Kenza admins read AI usage limits" on public.ai_usage_limits
for select to authenticated using ((select public.is_kenza_admin()));
create policy "Kenza admins update AI usage limits" on public.ai_usage_limits
for update to authenticated using ((select public.is_kenza_admin()))
with check ((select public.is_kenza_admin()));
create policy "Kenza admins read AI model pricing" on public.ai_model_pricing
for select to authenticated using ((select public.is_kenza_admin()));
create policy "Kenza admins update AI model pricing" on public.ai_model_pricing
for update to authenticated using ((select public.is_kenza_admin()))
with check ((select public.is_kenza_admin()));
create policy "Kenza admins read AI usage settings" on public.ai_usage_settings
for select to authenticated using ((select public.is_kenza_admin()));
create policy "Kenza admins update AI usage settings" on public.ai_usage_settings
for update to authenticated using ((select public.is_kenza_admin()))
with check ((select public.is_kenza_admin()));
create policy "Kenza admins read AI usage events" on public.ai_usage_events
for select to authenticated using ((select public.is_kenza_admin()));

revoke all on public.ai_usage_limits, public.ai_model_pricing, public.ai_usage_settings, public.ai_usage_events from anon, authenticated;
grant select, update on public.ai_usage_limits, public.ai_model_pricing, public.ai_usage_settings to authenticated;
grant select on public.ai_usage_events to authenticated;
grant all on public.ai_usage_limits, public.ai_model_pricing, public.ai_usage_settings, public.ai_usage_events to service_role;
grant usage, select on sequence public.ai_usage_events_id_seq to service_role;

create or replace function public.consume_ai_usage_attempt(
  p_service_key text,p_request_id uuid,p_attempt_no integer,p_model text
) returns jsonb
language plpgsql security definer set search_path=public,pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_limit public.ai_usage_limits%rowtype;
  v_tier text;
  v_daily_limit integer;
  v_used integer;
  v_recent_requests integer;
  v_existing boolean;
  v_day_start timestamptz := date_trunc('day', now() at time zone 'utc') at time zone 'utc';
begin
  if v_user_id is null then raise exception 'Authentication required' using errcode='28000'; end if;
  if p_service_key not in ('product_suggestions','image_review','image_search')
     or p_request_id is null or p_attempt_no is null or p_attempt_no < 1 or p_attempt_no > 20
     or p_model not in ('gemini-3.8-flash','gemini-3.5-flash-lite') then
    raise exception 'Invalid AI usage request' using errcode='22023';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_user_id::text,0));
  select * into v_limit from public.ai_usage_limits where service_key=p_service_key;
  if not found then raise exception 'AI usage limit is not configured'; end if;
  select exists(select 1 from public.ai_usage_events where user_id=v_user_id and service_key=p_service_key
    and request_id=p_request_id and attempt_no=p_attempt_no) into v_existing;
  if v_existing then
    select count(*)::integer into v_used from public.ai_usage_events
    where user_id=v_user_id and service_key=p_service_key and consumed_at>=v_day_start;
    v_tier := case when exists(select 1 from public.account_roles where user_id=v_user_id
      and role='pro_seller' and is_active=true) then 'pro_seller' else 'individual' end;
    v_daily_limit := case when v_tier='pro_seller' then v_limit.pro_seller_daily_limit else v_limit.individual_daily_limit end;
    return jsonb_build_object('allowed',true,'already_recorded',true,'tier',v_tier,
      'daily_limit',v_daily_limit,'used',v_used,'remaining',greatest(0,v_daily_limit-v_used));
  end if;
  select count(*)::integer into v_used from public.ai_usage_events
  where user_id=v_user_id and service_key=p_service_key and consumed_at>=v_day_start;
  v_tier := case when exists(select 1 from public.account_roles where user_id=v_user_id
    and role='pro_seller' and is_active=true) then 'pro_seller' else 'individual' end;
  v_daily_limit := case when v_tier='pro_seller' then v_limit.pro_seller_daily_limit else v_limit.individual_daily_limit end;
  if v_used>=v_daily_limit then
    return jsonb_build_object('allowed',false,'reason','daily_quota_exceeded','tier',v_tier,
      'daily_limit',v_daily_limit,'used',v_used,'remaining',0);
  end if;
  select count(distinct request_id)::integer into v_recent_requests from public.ai_usage_events
  where user_id=v_user_id and service_key=p_service_key and consumed_at>=now()-interval '60 seconds';
  if v_recent_requests>=v_limit.requests_per_minute then
    return jsonb_build_object('allowed',false,'reason','rate_limited','tier',v_tier,
      'daily_limit',v_daily_limit,'used',v_used,'remaining',greatest(0,v_daily_limit-v_used));
  end if;
  insert into public.ai_usage_events(user_id,service_key,request_id,attempt_no,model,tier)
  values(v_user_id,p_service_key,p_request_id,p_attempt_no,p_model);
  return jsonb_build_object('allowed',true,'already_recorded',false,'tier',v_tier,
    'daily_limit',v_daily_limit,'used',v_used+1,'remaining',greatest(0,v_daily_limit-v_used-1));
end;
$$;

create or replace function public.finish_ai_usage_attempt(
  p_service_key text,p_request_id uuid,p_attempt_no integer,p_http_status integer,p_succeeded boolean,
  p_input_tokens bigint default null,p_output_tokens bigint default null
) returns boolean
language plpgsql security definer set search_path=public,pg_temp
as $$
declare v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Authentication required' using errcode='28000'; end if;
  update public.ai_usage_events e
  set finished_at=now(),provider_http_status=p_http_status,succeeded=p_succeeded,
      input_tokens=case when p_input_tokens is null then null else greatest(0,p_input_tokens) end,
      output_tokens=case when p_output_tokens is null then null else greatest(0,p_output_tokens) end,
      estimated_cost_usd=case when p_input_tokens is null or p_output_tokens is null then null
        when ip.input_cost_per_million_usd is null or ip.output_cost_per_million_usd is null then null
        else (p_input_tokens::numeric*ip.input_cost_per_million_usd
          +p_output_tokens::numeric*ip.output_cost_per_million_usd)/1000000 end
  from public.ai_model_pricing ip
  where e.user_id=v_user_id and e.service_key=p_service_key and e.request_id=p_request_id
    and e.attempt_no=p_attempt_no and ip.model=e.model;
  return found;
end;
$$;
revoke all on function public.consume_ai_usage_attempt(text,uuid,integer,text) from public,anon;
revoke all on function public.finish_ai_usage_attempt(text,uuid,integer,integer,boolean,bigint,bigint) from public,anon;
grant execute on function public.consume_ai_usage_attempt(text,uuid,integer,text) to authenticated;
grant execute on function public.finish_ai_usage_attempt(text,uuid,integer,integer,boolean,bigint,bigint) to authenticated;

create or replace view public.ai_usage_daily_summary with (security_invoker=true) as
select date_trunc('day',consumed_at at time zone 'utc') as usage_day_utc,service_key,model,tier,
 count(*)::bigint as gemini_attempts,count(distinct user_id)::bigint as active_users,
 coalesce(sum(input_tokens),0)::bigint as input_tokens,coalesce(sum(output_tokens),0)::bigint as output_tokens,
 sum(estimated_cost_usd) as estimated_cost_usd
from public.ai_usage_events group by 1,2,3,4;
grant select on public.ai_usage_daily_summary to authenticated;
