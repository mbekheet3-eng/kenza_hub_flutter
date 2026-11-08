drop policy if exists disputes_participant_insert on public.disputes;
create policy disputes_participant_insert on public.disputes for insert to authenticated with check (
  private.is_active_user()
  and opened_by=(select auth.uid())
  and status='open'
  and exists(
    select 1 from public.orders o
    where o.id=order_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id))
  )
);

