create or replace function private.assign_delivery_courier(
  p_order_id uuid,
  p_courier_user_id uuid,
  p_reason text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_seller uuid;
  v_order_status text;
  v_assignment uuid;
begin
  select seller_profile_id, status
    into v_seller, v_order_status
  from public.orders
  where id = p_order_id
  for update;

  if not found or v_seller is null then
    raise exception 'ORDER_NOT_FOUND';
  end if;

  if not private.is_admin() and not private.is_seller_owner(v_seller) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  if v_order_status not in ('confirmed', 'processing', 'shipped') then
    raise exception 'COURIER_ASSIGNMENT_NOT_ALLOWED_FOR_ORDER_STATUS';
  end if;

  if not exists (
    select 1
    from public.courier_profiles c
    join public.users u on u.id = c.user_id
    where c.user_id = p_courier_user_id
      and c.is_active
      and u.is_active
  ) then
    raise exception 'COURIER_NOT_ACTIVE';
  end if;

  update public.delivery_assignments
  set status = 'revoked',
      ended_at = now()
  where order_id = p_order_id
    and ended_at is null;

  insert into public.delivery_assignments (
    order_id,
    courier_user_id,
    assigned_by
  )
  values (
    p_order_id,
    p_courier_user_id,
    auth.uid()
  )
  returning id into v_assignment;

  insert into public.admin_audit_log (
    actor_user_id,
    action,
    target_table,
    target_id,
    reason,
    after_data
  )
  values (
    auth.uid(),
    'delivery.courier_assigned',
    'delivery_assignments',
    v_assignment,
    p_reason,
    jsonb_build_object(
      'order_id', p_order_id,
      'courier_user_id', p_courier_user_id,
      'order_status', v_order_status
    )
  );

  return v_assignment;
end
$function$;