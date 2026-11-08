-- Allow active platform administrators to inspect quarantined product images
-- while preserving the existing public/follower/store-member visibility rules.
create or replace function private.can_read_product_image(p_product_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select private.is_admin()
    or exists (
      select 1
      from public.products p
      where p.id=p_product_id
        and p.moderation_status='approved'
        and (
          p.audience='public'
          or (
            p.audience='followers'
            and exists (
              select 1
              from public.follows f
              where f.follower_user_id=(select auth.uid())
                and f.followed_seller_profile_id=p.seller_id
            )
          )
          or private.has_seller_permission(p.seller_id,'products:read')
        )
    )
$$;

revoke all on function private.can_read_product_image(uuid) from public;
grant execute on function private.can_read_product_image(uuid) to anon,authenticated;
