-- Register device tokens through authenticated, ownership-checked RPCs.
-- Direct client writes to device_tokens are no longer needed.

create or replace function public.register_device_token(
  p_token text,
  p_platform text default 'android'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_token is null or length(btrim(p_token)) < 20 or length(p_token) > 4096 then
    raise exception 'Invalid device token' using errcode = '22023';
  end if;

  if p_platform not in ('android', 'ios') then
    raise exception 'Unsupported device platform' using errcode = '22023';
  end if;

  insert into public.device_tokens (
    user_id, token, platform, is_active, updated_at, last_seen_at
  )
  values (
    v_user_id, p_token, p_platform, true, now(), now()
  )
  on conflict (token) do update
  set
    user_id = excluded.user_id,
    platform = excluded.platform,
    is_active = true,
    updated_at = now(),
    last_seen_at = now();
end;
$$;

create or replace function public.deactivate_device_token(p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'Authentication required' using errcode = '28000';
  end if;

  if p_token is null or length(btrim(p_token)) < 20 or length(p_token) > 4096 then
    raise exception 'Invalid device token' using errcode = '22023';
  end if;

  update public.device_tokens
  set is_active = false, updated_at = now()
  where user_id = v_user_id and token = p_token;
end;
$$;

revoke all on function public.register_device_token(text, text) from public, anon, authenticated;
revoke all on function public.deactivate_device_token(text) from public, anon, authenticated;
grant execute on function public.register_device_token(text, text) to authenticated;
grant execute on function public.deactivate_device_token(text) to authenticated;

revoke all on table public.device_tokens from anon, authenticated;
