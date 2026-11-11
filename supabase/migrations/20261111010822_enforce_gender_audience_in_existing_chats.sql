drop policy if exists "Conversation participants can read conversations" on public.conversations;
create policy "Conversation participants can read conversations"
  on public.conversations for select to authenticated
  using (
    seller_id = (select auth.uid())
    or (
      buyer_id = (select auth.uid())
      and exists (
        select 1
        from public.products p
        join public.profiles buyer on buyer.id = conversations.buyer_id
        where p.id = conversations.product_id
          and (
            p.audience = 'all'
            or (p.audience = 'women_only' and buyer.gender = 'female')
            or (p.audience = 'men_only' and buyer.gender = 'male')
          )
      )
    )
  );

drop policy if exists "Conversation participants can read messages" on public.messages;
create policy "Conversation participants can read messages"
  on public.messages for select to authenticated
  using (
    exists (
      select 1
      from public.conversations c
      join public.products p on p.id = c.product_id
      join public.profiles buyer on buyer.id = c.buyer_id
      where c.id = messages.conversation_id
        and (
          c.seller_id = (select auth.uid())
          or (
            c.buyer_id = (select auth.uid())
            and (
              p.audience = 'all'
              or (p.audience = 'women_only' and buyer.gender = 'female')
              or (p.audience = 'men_only' and buyer.gender = 'male')
            )
          )
        )
    )
  );

drop policy if exists "Participants can send messages as themselves" on public.messages;
create policy "Participants can send messages as themselves"
  on public.messages for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and exists (
      select 1
      from public.conversations c
      join public.products p on p.id = c.product_id
      join public.profiles buyer on buyer.id = c.buyer_id
      where c.id = messages.conversation_id
        and (
          c.seller_id = (select auth.uid())
          or (
            c.buyer_id = (select auth.uid())
            and (
              p.audience = 'all'
              or (p.audience = 'women_only' and buyer.gender = 'female')
              or (p.audience = 'men_only' and buyer.gender = 'male')
            )
          )
        )
    )
  );
