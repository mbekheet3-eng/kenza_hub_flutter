create or replace function private.submit_order_review(
  p_order_id uuid,
  p_rating smallint,
  p_comment text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_seller uuid;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not private.is_active_user() then
    raise exception 'ACCOUNT_NOT_ACTIVE';
  end if;

  select seller_profile_id
    into v_seller
  from public.orders
  where id = p_order_id
    and buyer_id = auth.uid()
    and status = 'delivered';

  if v_seller is null then
    raise exception 'REVIEW_NOT_ALLOWED';
  end if;

  if p_rating not between 1 and 5 then
    raise exception 'INVALID_RATING';
  end if;

  insert into public.reviews (
    order_id,
    reviewer_user_id,
    seller_profile_id,
    rating,
    comment
  )
  values (
    p_order_id,
    auth.uid(),
    v_seller,
    p_rating,
    nullif(trim(p_comment), '')
  )
  returning id into v_id;

  return v_id;
end
$function$;
