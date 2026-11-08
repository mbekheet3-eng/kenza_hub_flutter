-- Keep only short-lived user-facing activity data for 60 days.
-- Orders, chats/messages, reports, disputes/evidence, user profiles,
-- addresses, and admin audit records are intentionally excluded.

create index if not exists notifications_created_at_retention_idx
  on public.notifications (created_at);

create index if not exists product_view_events_created_at_retention_idx
  on public.product_view_events (created_at);

create or replace function private.purge_expired_ephemeral_data()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_notifications bigint := 0;
  v_product_views bigint := 0;
  v_batch bigint := 0;
begin
  loop
    delete from public.notifications
    where ctid in (
      select ctid
      from public.notifications
      where created_at < pg_catalog.now() - interval '60 days'
      order by created_at
      limit 5000
    );
    get diagnostics v_batch = row_count;
    v_notifications := v_notifications + v_batch;
    exit when v_batch = 0;
  end loop;

  loop
    delete from public.product_view_events
    where ctid in (
      select ctid
      from public.product_view_events
      where created_at < pg_catalog.now() - interval '60 days'
      order by created_at
      limit 5000
    );
    get diagnostics v_batch = row_count;
    v_product_views := v_product_views + v_batch;
    exit when v_batch = 0;
  end loop;

  return pg_catalog.jsonb_build_object(
    'notifications_deleted', v_notifications,
    'product_view_events_deleted', v_product_views,
    'retention_days', 60
  );
end;
$function$;

revoke all on function private.purge_expired_ephemeral_data() from public;
revoke all on function private.purge_expired_ephemeral_data() from anon;
revoke all on function private.purge_expired_ephemeral_data() from authenticated;
grant execute on function private.purge_expired_ephemeral_data() to postgres;

comment on function private.purge_expired_ephemeral_data() is
  'Daily cleanup of notifications and product view events older than 60 days. Does not delete transactional, dispute, conversation, account, address, or admin audit records.';

do $schedule$
begin
  if not exists (
    select 1 from cron.job where jobname = 'ephemeral-data-retention-60-days-daily'
  ) then
    perform cron.schedule(
      'ephemeral-data-retention-60-days-daily',
      '30 3 * * *',
      'select private.purge_expired_ephemeral_data();'
    );
  end if;
end;
$schedule$;