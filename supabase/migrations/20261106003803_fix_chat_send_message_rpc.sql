begin;

-- Clients must send messages only through the validated RPC.
revoke insert on table public.messages from authenticated;
revoke insert (moderation_status) on table public.messages from authenticated;

create or replace function private.send_message(p_chat_id uuid, p_content text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := auth.uid();
  v_buyer_id uuid;
  v_seller_profile_id uuid;
  v_seller_owner_id uuid;
  v_message_id uuid;
  v_content text := pg_catalog.btrim(p_content);
begin
  if v_uid is null or not private.is_active_user() then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if p_chat_id is null then
    raise exception 'CHAT_NOT_FOUND' using errcode = '22023';
  end if;

  if v_content is null or pg_catalog.char_length(v_content) < 1
     or pg_catalog.char_length(v_content) > 4000 then
    raise exception 'INVALID_MESSAGE_CONTENT' using errcode = '22023';
  end if;

  select c.buyer_id, c.seller_profile_id, sp.owner_user_id
    into v_buyer_id, v_seller_profile_id, v_seller_owner_id
  from public.chats c
  join public.seller_profiles sp on sp.id = c.seller_profile_id
  where c.id = p_chat_id;

  if not found then
    raise exception 'CHAT_NOT_FOUND' using errcode = 'P0002';
  end if;

  if v_uid = v_buyer_id then
    null;
  elsif v_uid = v_seller_owner_id and private.is_seller_owner(v_seller_profile_id) then
    null;
  else
    raise exception 'CHAT_ACCESS_DENIED' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.user_blocks b
    where (b.blocker_user_id = v_buyer_id and b.blocked_user_id = v_seller_owner_id)
       or (b.blocker_user_id = v_seller_owner_id and b.blocked_user_id = v_buyer_id)
  ) then
    raise exception 'CHAT_BLOCKED' using errcode = '42501';
  end if;

  insert into public.messages (chat_id, sender_id, content)
  values (p_chat_id, v_uid, v_content)
  returning id into v_message_id;

  return v_message_id;
end;
$function$;

create or replace function public.send_message(p_chat_id uuid, p_content text)
returns uuid
language sql
security invoker
set search_path = ''
as $function$
  select private.send_message(p_chat_id, p_content);
$function$;

revoke all on function private.send_message(uuid, text) from public, anon, authenticated;
grant execute on function private.send_message(uuid, text) to postgres;

revoke all on function public.send_message(uuid, text) from public, anon, authenticated;
grant execute on function public.send_message(uuid, text) to authenticated;

commit;