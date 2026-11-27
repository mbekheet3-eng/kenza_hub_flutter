
alter table public.ai_model_pricing add constraint ai_model_pricing_scheduled_nonnegative check (
 (scheduled_input_cost_per_million_usd is null or scheduled_input_cost_per_million_usd>=0)
 and (scheduled_output_cost_per_million_usd is null or scheduled_output_cost_per_million_usd>=0)
);
create index if not exists ai_usage_limits_updated_by_idx on public.ai_usage_limits(updated_by);
create index if not exists ai_model_pricing_updated_by_idx on public.ai_model_pricing(updated_by);
create index if not exists ai_usage_settings_updated_by_idx on public.ai_usage_settings(updated_by);
create or replace function public.set_ai_usage_admin_audit()
returns trigger language plpgsql set search_path=public,pg_temp as $$
begin new.updated_at:=now(); new.updated_by:=auth.uid(); return new; end;
$$;
create trigger set_ai_usage_limits_audit before update on public.ai_usage_limits
for each row execute function public.set_ai_usage_admin_audit();
create trigger set_ai_model_pricing_audit before update on public.ai_model_pricing
for each row execute function public.set_ai_usage_admin_audit();
create trigger set_ai_usage_settings_audit before update on public.ai_usage_settings
for each row execute function public.set_ai_usage_admin_audit();
