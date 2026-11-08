
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name text,
  last_name text,
  username text unique,
  avatar_url text,
  bio text,
  language_preference text not null default 'ar' check (language_preference in ('ar','en')),
  role text not null default 'member' check (role in ('member','admin','support')),
  is_active boolean not null default true,
  default_region_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.regions (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  city_ar text not null default 'القاهرة',
  city_en text not null default 'Cairo',
  is_delivery_active boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(name_en, city_en)
);

alter table public.users add constraint users_default_region_fk
  foreign key (default_region_id) references public.regions(id) on delete set null;

create table public.categories (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.categories(id) on delete restrict,
  name_ar text not null,
  name_en text not null,
  slug text not null unique,
  icon_url text,
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.product_conditions (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  slug text not null unique,
  is_active boolean not null default true,
  display_order integer not null default 0
);
create table public.product_colors (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  hex_code text,
  is_active boolean not null default true,
  display_order integer not null default 0
);
create table public.product_sizes (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  size_group text not null check (size_group in ('clothing','shoes','children','home','general')),
  is_active boolean not null default true,
  display_order integer not null default 0
);
create table public.product_statuses (
  id uuid primary key default gen_random_uuid(),
  name_ar text not null,
  name_en text not null,
  slug text not null unique,
  is_active boolean not null default true
);
create table public.currencies (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z]{3}$'),
  name_ar text not null,
  name_en text not null,
  symbol text not null,
  is_active boolean not null default false
);

create table public.seller_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null unique references public.users(id) on delete restrict,
  seller_type text not null default 'seller' check (seller_type in ('seller','pro_seller')),
  business_type text check (business_type in ('individual','agency','online_store')),
  display_name text not null check (char_length(display_name) between 3 and 60),
  business_name text,
  bio text,
  avatar_url text,
  verification_status text not null default 'unverified' check (verification_status in ('unverified','pending','verified','rejected')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.seller_profile_members (
  id uuid primary key default gen_random_uuid(),
  seller_profile_id uuid not null references public.seller_profiles(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  member_role text not null default 'employee' check (member_role in ('owner','employee')),
  permissions jsonb not null default '{}'::jsonb check (jsonb_typeof(permissions) = 'object'),
  invited_by uuid references public.users(id) on delete set null,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  unique(seller_profile_id,user_id)
);

create table public.pro_seller_upgrade_requests (
  id uuid primary key default gen_random_uuid(),
  seller_profile_id uuid not null references public.seller_profiles(id) on delete cascade,
  requested_business_type text check (requested_business_type in ('individual','agency','online_store')),
  status text not null default 'pending' check (status in ('pending','approved','rejected','withdrawn')),
  applicant_note text,
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  review_note text,
  created_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.seller_profiles(id) on delete restrict,
  category_id uuid not null references public.categories(id) on delete restrict,
  title_ar text not null check (char_length(title_ar) between 3 and 140),
  title_en text,
  description_ar text,
  description_en text,
  price numeric(12,2) not null check (price > 0),
  currency_id uuid not null references public.currencies(id),
  condition_id uuid not null references public.product_conditions(id),
  color_id uuid references public.product_colors(id),
  size_id uuid references public.product_sizes(id),
  status_id uuid not null references public.product_statuses(id),
  brand_name text,
  audience text not null default 'public' check (audience in ('public','followers','private')),
  weight_kg numeric(6,2) check (weight_kg is null or weight_kg between 0 and 10),
  moderation_status text not null default 'pending' check (moderation_status in ('pending','approved','rejected','hidden')),
  views_count bigint not null default 0 check (views_count >= 0),
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.product_images (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  image_path text not null,
  display_order integer not null default 0,
  created_at timestamptz not null default now(),
  unique(product_id,display_order)
);

create table public.user_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  region_id uuid references public.regions(id) on delete set null,
  recipient_name text not null,
  recipient_phone text not null,
  address_line_1 text not null,
  address_line_2 text,
  landmark text,
  postal_code text,
  latitude numeric(10,7),
  longitude numeric(10,7),
  is_default boolean not null default false,
  is_deleted boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index user_addresses_one_default_idx on public.user_addresses(user_id) where is_default and not is_deleted;

create table public.favorites (
  user_id uuid not null references public.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(user_id,product_id)
);
create table public.follows (
  follower_user_id uuid not null references public.users(id) on delete cascade,
  followed_seller_profile_id uuid not null references public.seller_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(follower_user_id,followed_seller_profile_id),
  check (follower_user_id is not null)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  buyer_id uuid not null references public.users(id) on delete restrict,
  seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
  product_id uuid not null references public.products(id) on delete restrict,
  status text not null default 'pending_agreement' check (status in ('pending_agreement','confirmed','processing','shipped','delivered','cancelled','disputed','closed')),
  quantity integer not null default 1 check (quantity > 0),
  currency_id uuid not null references public.currencies(id),
  total_amount numeric(12,2) not null check (total_amount >= 0),
  agreement_snapshot jsonb,
  agreement_version text,
  buyer_confirmed_at timestamptz,
  seller_confirmed_at timestamptz,
  agreement_confirmed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_delivery_details (
  order_id uuid primary key references public.orders(id) on delete cascade,
  recipient_name text not null,
  recipient_phone text not null,
  address_line_1 text not null,
  address_line_2 text,
  landmark text,
  region_id uuid references public.regions(id) on delete set null,
  latitude numeric(10,7),
  longitude numeric(10,7),
  delivery_notes text,
  retention_expires_at timestamptz not null,
  legal_hold boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.delivery_assignments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  courier_user_id uuid not null references public.users(id) on delete restrict,
  assigned_by uuid not null references public.users(id) on delete restrict,
  status text not null default 'assigned' check (status in ('assigned','accepted','in_transit','delivered','cancelled','revoked')),
  assigned_at timestamptz not null default now(),
  ended_at timestamptz
);

create table public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  previous_status text,
  new_status text not null,
  action text not null,
  actor_id uuid references public.users(id) on delete set null,
  actor_role text,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete restrict,
  opened_by uuid not null references public.users(id) on delete restrict,
  status text not null default 'open' check (status in ('open','under_review','awaiting_response','resolved','rejected','closed')),
  reason text not null,
  description text,
  admin_decision text,
  resolved_by uuid references public.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.dispute_evidence (
  id uuid primary key default gen_random_uuid(),
  dispute_id uuid not null references public.disputes(id) on delete restrict,
  uploaded_by uuid not null references public.users(id) on delete restrict,
  storage_path text not null,
  caption text,
  created_at timestamptz not null default now()
);
create table public.dispute_status_consents (
  id uuid primary key default gen_random_uuid(),
  dispute_id uuid not null references public.disputes(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete restrict,
  proposed_status text not null,
  consented_at timestamptz not null default now(),
  unique(dispute_id,user_id,proposed_status)
);

create table public.chats (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete restrict,
  buyer_id uuid not null references public.users(id) on delete restrict,
  seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  unique(product_id,buyer_id)
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete restrict,
  content text not null check (char_length(content) between 1 and 4000),
  moderation_status text not null default 'pending_review' check (moderation_status in ('pending_review','approved','redacted','rejected')),
  created_at timestamptz not null default now()
);

create table public.auctions (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null unique references public.products(id) on delete restrict,
  seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
  starting_price numeric(12,2) not null check (starting_price > 0),
  minimum_increment numeric(12,2) not null default 1 check (minimum_increment > 0),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  status text not null default 'draft' check (status in ('draft','scheduled','live','ended','cancelled')),
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
create table public.auction_bids (
  id uuid primary key default gen_random_uuid(),
  auction_id uuid not null references public.auctions(id) on delete cascade,
  bidder_user_id uuid not null references public.users(id) on delete restrict,
  amount numeric(12,2) not null check (amount > 0),
  created_at timestamptz not null default now()
);
create table public.exchange_offers (
  id uuid primary key default gen_random_uuid(),
  proposer_seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
  target_seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
  offered_product_id uuid not null references public.products(id) on delete restrict,
  requested_product_id uuid not null references public.products(id) on delete restrict,
  status text not null default 'pending' check (status in ('pending','accepted','rejected','withdrawn','completed')),
  created_at timestamptz not null default now(),
  check (proposer_seller_profile_id <> target_seller_profile_id)
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete restrict,
  reviewer_user_id uuid not null references public.users(id) on delete restrict,
  seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
  rating smallint not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique(order_id,reviewer_user_id)
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  notification_type text not null,
  title text not null,
  body text,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.admin_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references public.users(id) on delete set null,
  action text not null,
  target_table text not null,
  target_id uuid,
  reason text,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);

create index products_seller_created_idx on public.products(seller_id,created_at desc);
create index products_category_status_idx on public.products(category_id,status_id,created_at desc);
create index products_publication_idx on public.products(moderation_status,published_at desc);
create index product_images_product_order_idx on public.product_images(product_id,display_order);
create index seller_members_user_active_idx on public.seller_profile_members(user_id) where revoked_at is null;
create index orders_buyer_created_idx on public.orders(buyer_id,created_at desc);
create index orders_seller_created_idx on public.orders(seller_profile_id,created_at desc);
create index delivery_assignments_courier_active_idx on public.delivery_assignments(courier_user_id) where ended_at is null;
create index disputes_status_created_idx on public.disputes(status,created_at);
create index messages_chat_created_idx on public.messages(chat_id,created_at);
create index bids_auction_amount_idx on public.auction_bids(auction_id,amount desc,created_at);
create index notifications_user_created_idx on public.notifications(user_id,created_at desc);

create function private.touch_updated_at()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at = now(); return new; end $$;

create function private.is_admin()
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.users u where u.id = (select auth.uid()) and u.role = 'admin' and u.is_active) $$;

create function private.is_seller_owner(p_profile_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.seller_profiles sp where sp.id = p_profile_id and sp.owner_user_id = (select auth.uid()) and sp.is_active) $$;

create function private.has_seller_permission(p_profile_id uuid,p_permission text)
returns boolean language sql stable security definer set search_path = ''
as $$ select exists(
  select 1 from public.seller_profile_members m
  where m.seller_profile_id = p_profile_id and m.user_id = (select auth.uid())
    and m.revoked_at is null
    and (m.member_role = 'owner' or coalesce((m.permissions ->> p_permission)::boolean,false))
) $$;

revoke all on all functions in schema private from public;
grant execute on function private.is_admin() to authenticated;
grant execute on function private.is_seller_owner(uuid) to authenticated;
grant execute on function private.has_seller_permission(uuid,text) to authenticated;

create function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.users(id,first_name,last_name,username,avatar_url)
  values (
    new.id,
    nullif(new.raw_user_meta_data->>'first_name',''),
    nullif(new.raw_user_meta_data->>'last_name',''),
    nullif(new.raw_user_meta_data->>'username',''),
    nullif(new.raw_user_meta_data->>'avatar_url','')
  )
  on conflict (id) do nothing;
  return new;
end $$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

create trigger users_touch_updated before update on public.users for each row execute function private.touch_updated_at();
create trigger seller_profiles_touch_updated before update on public.seller_profiles for each row execute function private.touch_updated_at();
create trigger products_touch_updated before update on public.products for each row execute function private.touch_updated_at();
create trigger addresses_touch_updated before update on public.user_addresses for each row execute function private.touch_updated_at();
create trigger orders_touch_updated before update on public.orders for each row execute function private.touch_updated_at();
create trigger disputes_touch_updated before update on public.disputes for each row execute function private.touch_updated_at();

alter table public.users enable row level security;
alter table public.regions enable row level security;
alter table public.categories enable row level security;
alter table public.product_conditions enable row level security;
alter table public.product_colors enable row level security;
alter table public.product_sizes enable row level security;
alter table public.product_statuses enable row level security;
alter table public.currencies enable row level security;
alter table public.seller_profiles enable row level security;
alter table public.seller_profile_members enable row level security;
alter table public.pro_seller_upgrade_requests enable row level security;
alter table public.products enable row level security;
alter table public.product_images enable row level security;
alter table public.user_addresses enable row level security;
alter table public.favorites enable row level security;
alter table public.follows enable row level security;
alter table public.orders enable row level security;
alter table public.order_delivery_details enable row level security;
alter table public.delivery_assignments enable row level security;
alter table public.order_status_history enable row level security;
alter table public.disputes enable row level security;
alter table public.dispute_evidence enable row level security;
alter table public.dispute_status_consents enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.auctions enable row level security;
alter table public.auction_bids enable row level security;
alter table public.exchange_offers enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_audit_log enable row level security;

create policy regions_read on public.regions for select to anon,authenticated using (is_active);
create policy categories_read on public.categories for select to anon,authenticated using (is_active);
create policy conditions_read on public.product_conditions for select to anon,authenticated using (is_active);
create policy colors_read on public.product_colors for select to anon,authenticated using (is_active);
create policy sizes_read on public.product_sizes for select to anon,authenticated using (is_active);
create policy statuses_read on public.product_statuses for select to anon,authenticated using (is_active);
create policy currencies_read on public.currencies for select to anon,authenticated using (is_active);

create policy users_read_self on public.users for select to authenticated using (id = (select auth.uid()));
create policy users_update_self on public.users for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy seller_profiles_public_read on public.seller_profiles for select to anon,authenticated using (is_active);
create policy seller_profiles_owner_update on public.seller_profiles for update to authenticated using (owner_user_id = (select auth.uid())) with check (owner_user_id = (select auth.uid()));
create policy seller_members_read_self_or_owner on public.seller_profile_members for select to authenticated using (user_id = (select auth.uid()) or private.is_seller_owner(seller_profile_id));
create policy pro_upgrade_owner_read on public.pro_seller_upgrade_requests for select to authenticated using (private.is_seller_owner(seller_profile_id));
create policy pro_upgrade_owner_insert on public.pro_seller_upgrade_requests for insert to authenticated with check (private.is_seller_owner(seller_profile_id) and status = 'pending' and reviewed_by is null and reviewed_at is null);

create policy products_public_or_owner_read on public.products for select to anon,authenticated using (
  (moderation_status = 'approved' and audience = 'public')
  or (auth.uid() is not null and private.has_seller_permission(seller_id,'products:read'))
  or (auth.uid() is not null and private.is_admin())
);
create policy products_insert_permission on public.products for insert to authenticated with check (private.has_seller_permission(seller_id,'products:create'));
create policy products_update_permission on public.products for update to authenticated using (private.has_seller_permission(seller_id,'products:update')) with check (private.has_seller_permission(seller_id,'products:update'));
create policy products_delete_permission on public.products for delete to authenticated using (private.has_seller_permission(seller_id,'products:delete'));
create policy product_images_read on public.product_images for select to anon,authenticated using (
  exists(select 1 from public.products p where p.id = product_id and (
    (p.moderation_status='approved' and p.audience='public')
    or (auth.uid() is not null and private.has_seller_permission(p.seller_id,'products:read'))
  ))
);
create policy product_images_insert on public.product_images for insert to authenticated with check (
  exists(select 1 from public.products p where p.id=product_id and private.has_seller_permission(p.seller_id,'products:update'))
);
create policy product_images_delete on public.product_images for delete to authenticated using (
  exists(select 1 from public.products p where p.id=product_id and private.has_seller_permission(p.seller_id,'products:update'))
);

create policy addresses_owner_all on public.user_addresses for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy favorites_owner_all on public.favorites for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy follows_owner_all on public.follows for all to authenticated using (follower_user_id=(select auth.uid())) with check (follower_user_id=(select auth.uid()));

create policy orders_buyer_or_seller_owner_read on public.orders for select to authenticated using (
  buyer_id=(select auth.uid()) or private.is_seller_owner(seller_profile_id) or private.is_admin()
);
create policy delivery_details_no_direct_client_access on public.order_delivery_details for select to authenticated using (false);
create policy delivery_assignments_courier_or_owner_read on public.delivery_assignments for select to authenticated using (
  courier_user_id=(select auth.uid()) or private.is_seller_owner((select o.seller_profile_id from public.orders o where o.id=order_id)) or private.is_admin()
);
create policy order_history_participant_read on public.order_status_history for select to authenticated using (
  exists(select 1 from public.orders o where o.id=order_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id)))
);
create policy disputes_participant_read on public.disputes for select to authenticated using (
  exists(select 1 from public.orders o where o.id=order_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id))) or private.is_admin()
);
create policy disputes_participant_insert on public.disputes for insert to authenticated with check (
  opened_by=(select auth.uid()) and status='open'
  and exists(select 1 from public.orders o where o.id=order_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id)))
);
create policy dispute_evidence_participant_read on public.dispute_evidence for select to authenticated using (
  exists(select 1 from public.disputes d join public.orders o on o.id=d.order_id
    where d.id=dispute_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id))) or private.is_admin()
);
create policy dispute_evidence_participant_insert on public.dispute_evidence for insert to authenticated with check (
  uploaded_by=(select auth.uid()) and exists(select 1 from public.disputes d join public.orders o on o.id=d.order_id
    where d.id=dispute_id and (o.buyer_id=(select auth.uid()) or private.is_seller_owner(o.seller_profile_id)))
);
create policy dispute_consents_read on public.dispute_status_consents for select to authenticated using (user_id=(select auth.uid()) or private.is_admin());
create policy dispute_consents_insert on public.dispute_status_consents for insert to authenticated with check (user_id=(select auth.uid()));

create policy chats_participant_read on public.chats for select to authenticated using (
  buyer_id=(select auth.uid()) or private.is_seller_owner(seller_profile_id)
);
create policy messages_participant_read on public.messages for select to authenticated using (
  exists(select 1 from public.chats c where c.id=chat_id and (c.buyer_id=(select auth.uid()) or private.is_seller_owner(c.seller_profile_id)))
);
-- Message writes deliberately remain closed until the approved reject-vs-redact contact policy is implemented server-side.

create policy auctions_public_read on public.auctions for select to anon,authenticated using (
  status in ('scheduled','live','ended') and exists(select 1 from public.products p where p.id=product_id and p.moderation_status='approved' and p.audience='public')
);
create policy bids_public_read on public.auction_bids for select to anon,authenticated using (
  exists(select 1 from public.auctions a where a.id=auction_id and a.status in ('live','ended'))
);
create policy exchange_participants_read on public.exchange_offers for select to authenticated using (
  private.has_seller_permission(proposer_seller_profile_id,'exchange:manage') or private.has_seller_permission(target_seller_profile_id,'exchange:manage')
);
create policy reviews_public_read on public.reviews for select to anon,authenticated using (true);
create policy notifications_owner_all on public.notifications for all to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy audit_admin_read on public.admin_audit_log for select to authenticated using (private.is_admin());
-- Audit is append-only: no client insert/update/delete policies.

revoke all on all tables in schema public from anon,authenticated;
grant select on public.regions,public.categories,public.product_conditions,public.product_colors,public.product_sizes,public.product_statuses,public.currencies,public.seller_profiles,public.products,public.product_images,public.auctions,public.auction_bids,public.reviews to anon;
grant select on public.users to authenticated;
revoke select on public.users from authenticated;
grant select (id,first_name,last_name,username,avatar_url,bio,language_preference,created_at,updated_at) on public.users to authenticated;
grant update (first_name,last_name,username,avatar_url,bio,language_preference,default_region_id) on public.users to authenticated;
grant select on public.regions,public.categories,public.product_conditions,public.product_colors,public.product_sizes,public.product_statuses,public.currencies,public.seller_profiles,public.products,public.product_images,public.auctions,public.auction_bids,public.reviews to authenticated;
grant select,insert,update,delete on public.favorites,public.follows,public.user_addresses to authenticated;
grant select on public.seller_profile_members,public.pro_seller_upgrade_requests,public.orders,public.delivery_assignments,public.order_status_history,public.disputes,public.dispute_evidence,public.dispute_status_consents,public.chats,public.messages,public.exchange_offers,public.notifications,public.admin_audit_log to authenticated;
grant insert on public.pro_seller_upgrade_requests,public.disputes,public.dispute_evidence,public.dispute_status_consents to authenticated;
grant select,insert on public.messages to authenticated;
grant usage,select on all sequences in schema public to authenticated;

alter default privileges for role postgres in schema public revoke all on tables from anon,authenticated;
alter default privileges for role postgres in schema public revoke all on sequences from anon,authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from public,anon,authenticated;

insert into public.regions(name_ar,name_en,is_delivery_active) values
('المعادي','Maadi',true),
('الدقي','Dokki',true),
('العجوزة','Agouza',true),
('المهندسين','Mohandessin',true),
('وسط البلد','Downtown Cairo',true),
('المنيل','Manial',true);

insert into public.categories(parent_id,name_ar,name_en,slug,display_order) values
(null,'مستلزمات أطفال','Kids Supplies','kids-supplies',1),
(null,'مستلزمات المنزل','Home Supplies','home-supplies',2),
(null,'ملابس','Clothes','clothes',3),
(null,'أحذية','Shoes','shoes',4);

insert into public.categories(parent_id,name_ar,name_en,slug,display_order)
select p.id,v.name_ar,v.name_en,v.slug,v.display_order
from public.categories p
cross join (values
 ('رجالي','Men','clothes-men',1),
 ('حريمي','Women','clothes-women',2),
 ('أطفال','Kids','clothes-kids',3)
) v(name_ar,name_en,slug,display_order)
where p.slug='clothes';

insert into public.categories(parent_id,name_ar,name_en,slug,display_order)
select p.id,v.name_ar,v.name_en,v.slug,v.display_order
from public.categories p
cross join (values
 ('رجالي','Men','shoes-men',1),
 ('حريمي','Women','shoes-women',2),
 ('أطفال','Kids','shoes-kids',3)
) v(name_ar,name_en,slug,display_order)
where p.slug='shoes';

insert into public.product_conditions(name_ar,name_en,slug,display_order) values
('جديد','New','new',1),('بحالة ممتازة','Excellent','excellent',2),('بحالة جيدة','Good','good',3);
insert into public.product_statuses(name_ar,name_en,slug) values
('مسودة','Draft','draft'),('قيد المراجعة','Pending review','pending_review'),('متاح','Available','available'),('مباع','Sold','sold'),('مخفي','Hidden','hidden');
insert into public.currencies(code,name_ar,name_en,symbol,is_active) values ('EGP','جنيه مصري','Egyptian Pound','ج.م',true);
