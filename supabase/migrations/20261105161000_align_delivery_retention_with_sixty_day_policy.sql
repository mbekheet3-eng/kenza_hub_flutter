create or replace function private.apply_delivery_retention_from_order()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_open_dispute boolean;
begin
  if new.status is distinct from old.status and new.status in ('delivered','closed') then
    select exists(select 1 from public.disputes d
      where d.order_id=new.id and d.status in ('open','under_review','awaiting_response')) into v_open_dispute;
    update public.order_delivery_details
      set legal_hold=v_open_dispute,
          retention_expires_at=case when v_open_dispute then null else now()+interval '60 days' end
      where order_id=new.id;
  end if;
  return new;
end;
$$;

create or replace function private.apply_delivery_retention_from_dispute()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_order_status text;
begin
  select status into v_order_status from public.orders where id=new.order_id;
  if new.status in ('open','under_review','awaiting_response') then
    update public.order_delivery_details set legal_hold=true,retention_expires_at=null where order_id=new.order_id;
  elsif new.status in ('resolved','rejected','closed') then
    update public.order_delivery_details
      set legal_hold=false,
          retention_expires_at=case when v_order_status in ('delivered','closed') then now()+interval '60 days' else null end
      where order_id=new.order_id;
  end if;
  return new;
end;
$$;
