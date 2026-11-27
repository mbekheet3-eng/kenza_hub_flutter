
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
  if p_service_key is null or p_service_key not in ('product_suggestions','image_review','image_search')
     or p_request_id is null or p_attempt_no is null or p_attempt_no < 1 or p_attempt_no > 20
     or p_model is null or p_model not in ('gemini-3.8-flash','gemini-3.5-flash-lite') then
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
  if v_used>=v_daily_limit then return jsonb_build_object('allowed',false,'reason','daily_quota_exceeded',
    'tier',v_tier,'daily_limit',v_daily_limit,'used',v_used,'remaining',0); end if;
  select count(distinct request_id)::integer into v_recent_requests from public.ai_usage_events
  where user_id=v_user_id and service_key=p_service_key and consumed_at>=now()-interval '60 seconds';
  if v_recent_requests>=v_limit.requests_per_minute then return jsonb_build_object('allowed',false,
    'reason','rate_limited','tier',v_tier,'daily_limit',v_daily_limit,'used',v_used,
    'remaining',greatest(0,v_daily_limit-v_used)); end if;
  insert into public.ai_usage_events(user_id,service_key,request_id,attempt_no,model,tier)
  values(v_user_id,p_service_key,p_request_id,p_attempt_no,p_model,v_tier);
  return jsonb_build_object('allowed',true,'already_recorded',false,'tier',v_tier,
    'daily_limit',v_daily_limit,'used',v_used+1,'remaining',greatest(0,v_daily_limit-v_used-1));
end;
$$;
