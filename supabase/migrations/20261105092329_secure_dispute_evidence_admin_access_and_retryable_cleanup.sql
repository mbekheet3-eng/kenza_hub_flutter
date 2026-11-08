
create policy "dispute_evidence_object_admin_read"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'dispute-evidence'
  and private.is_admin()
);

create or replace function public.dispute_evidence_existing_storage_paths(p_paths text[])
returns text[]
language sql
security definer
set search_path = ''
as $function$
  select coalesce(array_agg(o.name order by o.name), array[]::text[])
  from storage.objects o
  where o.bucket_id = 'dispute-evidence'
    and o.name = any(coalesce(p_paths, array[]::text[]));
$function$;

revoke all on function public.dispute_evidence_existing_storage_paths(text[]) from public, anon, authenticated;
grant execute on function public.dispute_evidence_existing_storage_paths(text[]) to service_role;
