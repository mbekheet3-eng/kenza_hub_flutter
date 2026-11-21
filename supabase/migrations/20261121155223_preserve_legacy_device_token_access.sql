-- Keep older installed app versions working during the rollout.
-- Newer app versions use the authenticated RPCs; these grants remain protected by RLS.
grant select, insert, update, delete
on table public.device_tokens
to authenticated;
