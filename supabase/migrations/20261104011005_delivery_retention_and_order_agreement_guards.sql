-- Delivery retention starts seven days after delivery and closure, not at order creation.
alter table public.order_delivery_details alter column retention_expires_at drop not null;
alter table public.order_delivery_details alter column retention_expires_at drop default;

create or replace function private.get_my_delivery_details(p_order_id uuid)
returns table(
  order_id uuid,recipient_name text,recipient_phone text,address_line_1 text,address_line_2 text,
  landmark text,region_id uuid,latitude numeric,longitude numeric,delivery_notes text
)
language plpgsql security definer set search_path=''
as $$
begin
 if auth.uid() is null or not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 return query
 select d.order_id,d.recipient_name,d.recipient_phone,d.address_line_1,d.address_line_2,
   d.landmark,d.region_id,d.latitude,d.longitude,d.delivery_notes
 from public.order_delivery_details d
 join public.delivery_assignments a on a.order_id=d.order_id
 where d.order_id=p_order_id and a.courier_user_id=auth.uid()
   and a.ended_at is null and a.status in ('assigned','accepted','in_transit')
   and (d.retention_expires_at is null or d.retention_expires_at>now() or d.legal_hold);
end $$;

create or replace function private.admin_get_delivery_details(p_order_id uuid,p_reason text)
returns table(
  order_id uuid,recipient_name text,recipient_phone text,address_line_1 text,address_line_2 text,
  landmark text,region_id uuid,latitude numeric,longitude numeric,delivery_notes text
)
language plpgsql security definer set search_path=''
as $$
begin
 if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
 if p_reason is null or char_length(trim(p_reason))<8 then raise exception 'AUDIT_REASON_REQUIRED'; end if;
 insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason)
 values(auth.uid(),'delivery_details.exceptional_access','order_delivery_details',p_order_id,trim(p_reason));
 return query select d.order_id,d.recipient_name,d.recipient_phone,d.address_line_1,d.address_line_2,
   d.landmark,d.region_id,d.latitude,d.longitude,d.delivery_notes
 from public.order_delivery_details d where d.order_id=p_order_id;
end $$;
revoke all on function private.admin_get_delivery_details(uuid,text) from public,anon;
grant execute on function private.admin_get_delivery_details(uuid,text) to authenticated;
create function public.admin_get_delivery_details(p_order_id uuid,p_reason text)
returns table(order_id uuid,recipient_name text,recipient_phone text,address_line_1 text,address_line_2 text,landmark text,region_id uuid,latitude numeric,longitude numeric,delivery_notes text)
language sql set search_path=''
as $$ select * from private.admin_get_delivery_details($1,$2) $$;
revoke all on function public.admin_get_delivery_details(uuid,text) from public,anon;
grant execute on function public.admin_get_delivery_details(uuid,text) to authenticated;

create or replace function private.apply_delivery_retention_from_order()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_open_dispute boolean;
begin
 if new.status is distinct from old.status and new.status in ('delivered','closed') then
   select exists(select 1 from public.disputes d where d.order_id=new.id and d.status in ('open','under_review','awaiting_response')) into v_open_dispute;
   update public.order_delivery_details
   set legal_hold=v_open_dispute,
       retention_expires_at=case when v_open_dispute then null else now()+interval '7 days' end
   where order_id=new.id;
 end if;
 return new;
end $$;
create trigger orders_delivery_retention after update of status on public.orders
for each row execute function private.apply_delivery_retention_from_order();

create or replace function private.apply_delivery_retention_from_dispute()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_order_status text;
begin
 select status into v_order_status from public.orders where id=new.order_id;
 if new.status in ('open','under_review','awaiting_response') then
   update public.order_delivery_details set legal_hold=true,retention_expires_at=null where order_id=new.order_id;
 elsif new.status in ('resolved','rejected','closed') then
   update public.order_delivery_details
   set legal_hold=false,
       retention_expires_at=case when v_order_status in ('delivered','closed') then now()+interval '7 days' else null end
   where order_id=new.order_id;
 end if;
 return new;
end $$;
create trigger disputes_delivery_retention after insert or update of status on public.disputes
for each row execute function private.apply_delivery_retention_from_dispute();

create or replace function private.purge_expired_delivery_details()
returns bigint language plpgsql security definer set search_path=''
as $$
declare v_count bigint;
begin
 delete from public.order_delivery_details
 where retention_expires_at is not null and retention_expires_at<=now() and legal_hold=false;
 get diagnostics v_count=row_count;
 return v_count;
end $$;
revoke all on function private.purge_expired_delivery_details() from public,anon,authenticated;
-- No scheduler is attached: the approved retention scheduler decision is still open.

create or replace function private.prevent_order_agreement_mutation()
returns trigger language plpgsql set search_path=''
as $$
begin
 if old.agreement_confirmed_at is not null and (
   new.agreement_snapshot is distinct from old.agreement_snapshot
   or new.agreement_version is distinct from old.agreement_version
   or new.agreed_unit_price is distinct from old.agreed_unit_price
   or new.agreed_shipping_method is distinct from old.agreed_shipping_method
   or new.agreed_shipping_cost is distinct from old.agreed_shipping_cost
   or new.agreed_fees is distinct from old.agreed_fees
   or new.agreed_delivery_terms is distinct from old.agreed_delivery_terms
 ) then raise exception 'ORDER_AGREEMENT_IMMUTABLE'; end if;
 return new;
end $$;
create trigger orders_agreement_immutable before update on public.orders
for each row execute function private.prevent_order_agreement_mutation();

create trigger order_status_history_append_only before update or delete on public.order_status_history
for each row execute function private.reject_mutation();

create or replace function private.create_offer(p_product_id uuid,p_offered_price numeric,p_expires_at timestamptz default null)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_id uuid;
begin
 if not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 select seller_id into v_seller from public.products where id=p_product_id and moderation_status='approved' and audience='public';
 if v_seller is null then raise exception 'PRODUCT_NOT_AVAILABLE'; end if;
 if private.has_seller_permission(v_seller,'products:read') then raise exception 'SELF_OFFER_NOT_ALLOWED'; end if;
 if p_offered_price<=0 or p_offered_price >= (select price from public.products where id=p_product_id) then raise exception 'INVALID_OFFER_PRICE'; end if;
 insert into public.offers(product_id,seller_profile_id,buyer_user_id,offered_price,expires_at)
 values(p_product_id,v_seller,auth.uid(),p_offered_price,p_expires_at) returning id into v_id;
 return v_id;
end $$;

