-- Pro Seller inventory variants: color + size + available quantity.
-- Existing individual/used listings remain single-unit products.
alter table public.products add column if not exists has_variants boolean not null default false;
create table if not exists public.product_variants (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete cascade,
 color text, size text, quantity integer not null check (quantity >= 0),
 created_at timestamptz not null default now(),
 constraint product_variants_color_or_size check (color is not null or size is not null),
 constraint product_variants_id_product_unique unique (id, product_id)
);
create unique index if not exists product_variants_unique_combination on public.product_variants(product_id, coalesce(color,''), coalesce(size,''));
alter table public.product_variants enable row level security;
grant select, insert, update, delete on public.product_variants to authenticated;
grant select on public.product_variants to anon;
drop policy if exists "read variants of visible products" on public.product_variants;
create policy "read variants of visible products" on public.product_variants for select to anon, authenticated using (exists (select 1 from public.products p where p.id=product_id and (p.status='published' or p.owner_id=(select auth.uid()))));
drop policy if exists "pro seller owner manages variants" on public.product_variants;
create policy "pro seller owner manages variants" on public.product_variants for all to authenticated using (exists (select 1 from public.products p where p.id=product_id and p.owner_id=(select auth.uid()) and exists (select 1 from public.account_roles r where r.user_id=(select auth.uid()) and r.role='pro_seller' and r.is_active))) with check (exists (select 1 from public.products p where p.id=product_id and p.owner_id=(select auth.uid()) and exists (select 1 from public.account_roles r where r.user_id=(select auth.uid()) and r.role='pro_seller' and r.is_active)));
create or replace function public.guard_product_variant_mode() returns trigger language plpgsql set search_path='' as $$ begin if new.has_variants and not exists (select 1 from public.account_roles r where r.user_id=new.owner_id and r.role='pro_seller' and r.is_active) then raise exception 'Only active Pro Sellers can manage product variants' using errcode='42501'; end if; return new; end; $$;
drop trigger if exists trg_guard_product_variant_mode on public.products;
create trigger trg_guard_product_variant_mode before insert or update of has_variants, owner_id on public.products for each row execute function public.guard_product_variant_mode();
alter table public.product_orders add column if not exists variant_id uuid, add column if not exists quantity integer not null default 1;
alter table public.product_orders drop constraint if exists product_orders_quantity_positive;
alter table public.product_orders add constraint product_orders_quantity_positive check (quantity>0);
alter table public.product_orders drop constraint if exists product_orders_variant_product_fk;
alter table public.product_orders add constraint product_orders_variant_product_fk foreign key (variant_id,product_id) references public.product_variants(id,product_id) on delete restrict;
drop index if exists public.product_orders_one_successful_order_per_product;
create unique index product_orders_one_successful_order_per_product on public.product_orders(product_id) where variant_id is null and status in ('accepted','delivered','completed');
create or replace function public.validate_product_order_insert() returns trigger language plpgsql set search_path='' as $$
declare v_owner_id uuid; v_price numeric; v_currency text; v_product_status text; v_has_variants boolean; v_available integer;
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(new.product_id::text||':'||auth.uid()::text,0));
 if exists(select 1 from public.product_orders o where o.product_id=new.product_id and o.buyer_id=auth.uid() and o.status in ('pending','accepted','delivered')) then raise exception 'An active purchase request already exists for this product' using errcode='23505'; end if;
 select p.owner_id,p.price,p.currency,p.status,p.has_variants into v_owner_id,v_price,v_currency,v_product_status,v_has_variants from public.products p where p.id=new.product_id;
 if not found or v_product_status<>'published' then raise exception 'Product is not available for purchase' using errcode='23514'; end if;
 if v_owner_id=auth.uid() then raise exception 'You cannot purchase your own product' using errcode='23514'; end if;
 if v_price<=0 then raise exception 'Product price must be greater than zero' using errcode='23514'; end if;
 if v_has_variants then
  if new.variant_id is null or new.quantity<1 then raise exception 'Choose a product variant and quantity' using errcode='23514'; end if;
  select v.quantity into v_available from public.product_variants v where v.id=new.variant_id and v.product_id=new.product_id;
  if not found or new.quantity>v_available then raise exception 'out_of_stock' using errcode='23514'; end if;
 else
  if new.variant_id is not null or new.quantity<>1 then raise exception 'Single-unit listings can only be requested one at a time' using errcode='23514'; end if;
 end if;
 new.buyer_id:=auth.uid(); new.seller_id:=v_owner_id; new.agreed_price:=v_price*new.quantity; new.currency:=v_currency; new.status:='pending'; new.created_at:=now(); new.updated_at:=now(); new.expires_at:=now()+interval '48 hours'; new.reminder_sent_at:=null; return new;
end; $$;
create or replace function public.validate_product_order_status_transition() returns trigger language plpgsql set search_path='' as $$
declare v_owner_id uuid; v_price numeric; v_currency text; v_product_status text; v_has_variants boolean; v_affected integer;
begin
 if new.status is distinct from old.status then
  if not ((old.status='pending' and new.status in ('accepted','rejected','cancelled','expired')) or (old.status='accepted' and new.status='delivered') or (old.status='delivered' and new.status='completed')) then raise exception 'Invalid purchase-order status transition: % -> %',old.status,new.status using errcode='23514'; end if;
  if new.status='accepted' then
   select p.owner_id,p.price,p.currency,p.status,p.has_variants into v_owner_id,v_price,v_currency,v_product_status,v_has_variants from public.products p where p.id=new.product_id;
   if not found or v_product_status<>'published' or v_owner_id<>new.seller_id or v_price*new.quantity<>new.agreed_price or v_currency<>new.currency or v_has_variants<>(new.variant_id is not null) then raise exception 'The product price or availability changed; refresh the listing before accepting' using errcode='23514'; end if;
   if new.variant_id is not null then
    update public.product_variants set quantity=quantity-new.quantity where id=new.variant_id and product_id=new.product_id and quantity>=new.quantity;
    get diagnostics v_affected=row_count;
    if v_affected=0 then raise exception 'out_of_stock' using errcode='23514'; end if;
   end if;
  end if;
 end if;
 new.updated_at:=now(); return new;
end; $$;
