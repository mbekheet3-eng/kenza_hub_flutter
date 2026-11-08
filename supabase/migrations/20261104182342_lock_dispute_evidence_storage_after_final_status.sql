-- Prevent orphaned evidence uploads after a dispute becomes final.
drop policy if exists dispute_evidence_object_insert on storage.objects;

create policy dispute_evidence_object_insert
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'dispute-evidence'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and private.is_dispute_participant(((storage.foldername(name))[1])::uuid)
  and exists (
    select 1
    from public.disputes d
    where d.id = ((storage.foldername(name))[1])::uuid
      and d.status not in ('resolved', 'rejected', 'closed')
  )
);

comment on policy dispute_evidence_object_insert on storage.objects is
  'Only dispute participants may upload evidence objects while the dispute is non-final.';
