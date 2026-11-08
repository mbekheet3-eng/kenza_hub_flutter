
-- A recipient Pro Seller is not required to be a member of the sender's profile.
create or replace function private.create_exchange_offer(
 p_source_seller_profile_id uuid,p_target_seller_profile_id uuid,p_offered_product_id uuid,p_requested_product_id uuid
) returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
 if not private.has_seller_permission(p_source_seller_profile_id,'exchange:manage') then raise exception 'EXCHANGE_PERMISSION_REQUIRED'; end if;
 if not exists(select 1 from public.seller_profiles where id=p_source_seller_profile_id and seller_type='pro_seller' and is_active) then raise exception 'PRO_SELLER_ONLY'; end if;
 if not exists(select 1 from public.seller_profiles where id=p_target_seller_profile_id and seller_type='pro_seller' and is_active) then raise exception 'TARGET_MUST_BE_PRO_SELLER'; end if;
 if p_source_seller_profile_id=p_target_seller_profile_id then raise exception 'SAME_SELLER_NOT_ALLOWED'; end if;
 if not exists(select 1 from public.products where id=p_offered_product_id and seller_id=p_source_seller_profile_id and moderation_status='approved') then raise exception 'OFFERED_PRODUCT_NOT_OWNED'; end if;
 if not exists(select 1 from public.products where id=p_requested_product_id and seller_id=p_target_seller_profile_id and moderation_status='approved') then raise exception 'REQUESTED_PRODUCT_NOT_OWNED'; end if;
 insert into public.exchange_offers(proposer_seller_profile_id,target_seller_profile_id,offered_product_id,requested_product_id)
 values(p_source_seller_profile_id,p_target_seller_profile_id,p_offered_product_id,p_requested_product_id) returning id into v_id;
 return v_id;
end $$;

create table public.brands (
 id uuid primary key default gen_random_uuid(),
 name_ar text not null,
 name_en text not null,
 slug text not null unique,
 is_active boolean not null default true,
 created_at timestamptz not null default now()
);
alter table public.products add column brand_id uuid references public.brands(id) on delete set null;
create table public.brand_follows (
 user_id uuid not null references public.users(id) on delete cascade,
 brand_id uuid not null references public.brands(id) on delete cascade,
 created_at timestamptz not null default now(),
 primary key(user_id,brand_id)
);

create table public.user_preferences (
 user_id uuid primary key references public.users(id) on delete cascade,
 notifications_enabled boolean not null default true,
 chat_notifications boolean not null default true,
 order_notifications boolean not null default true,
 auction_notifications boolean not null default true,
 marketing_notifications boolean not null default false,
 updated_at timestamptz not null default now()
);

create table public.reports (
 id uuid primary key default gen_random_uuid(),
 reporter_user_id uuid not null references public.users(id) on delete restrict,
 target_type text not null check(target_type in ('product','user','seller_profile','message')),
 target_id uuid not null,
 reason text not null,
 details text,
 status text not null default 'pending' check(status in ('pending','under_review','resolved','rejected')),
 reviewed_by uuid references public.users(id) on delete set null,
 reviewed_at timestamptz,
 review_note text,
 created_at timestamptz not null default now()
);

create table public.referrals (
 id uuid primary key default gen_random_uuid(),
 referrer_user_id uuid not null references public.users(id) on delete restrict,
 referred_user_id uuid not null unique references public.users(id) on delete restrict,
 referral_code text not null,
 status text not null default 'registered' check(status in ('registered','qualified','cancelled')),
 created_at timestamptz not null default now(),
 unique(referrer_user_id,referred_user_id)
);

create table public.help_articles (
 id uuid primary key default gen_random_uuid(),
 slug text not null unique,
 locale text not null default 'ar' check(locale in ('ar','en')),
 title text not null,
 content text not null,
 category text,
 is_published boolean not null default false,
 display_order integer not null default 0,
 published_at timestamptz,
 updated_at timestamptz not null default now()
);

create table public.platform_policy_versions (
 id uuid primary key default gen_random_uuid(),
 policy_type text not null,
 version text not null,
 locale text not null default 'ar' check(locale in ('ar','en')),
 content text not null,
 effective_at timestamptz not null,
 is_active boolean not null default false,
 created_at timestamptz not null default now(),
 unique(policy_type,version,locale)
);

create table public.offers (
 id uuid primary key default gen_random_uuid(),
 product_id uuid not null references public.products(id) on delete restrict,
 seller_profile_id uuid not null references public.seller_profiles(id) on delete restrict,
 buyer_user_id uuid not null references public.users(id) on delete restrict,
 offered_price numeric(12,2) not null check(offered_price>0),
 status text not null default 'pending' check(status in ('pending','accepted','rejected','withdrawn','expired')),
 expires_at timestamptz,
 responded_at timestamptz,
 created_at timestamptz not null default now()
);

create index brand_follows_brand_idx on public.brand_follows(brand_id);
create index reports_status_created_idx on public.reports(status,created_at);
create index referrals_referrer_created_idx on public.referrals(referrer_user_id,created_at desc);
create index offers_seller_status_idx on public.offers(seller_profile_id,status,created_at desc);
create index offers_buyer_created_idx on public.offers(buyer_user_id,created_at desc);

alter table public.brands enable row level security;
alter table public.brand_follows enable row level security;
alter table public.user_preferences enable row level security;
alter table public.reports enable row level security;
alter table public.referrals enable row level security;
alter table public.help_articles enable row level security;
alter table public.platform_policy_versions enable row level security;
alter table public.offers enable row level security;

create policy brands_public_read on public.brands for select to anon,authenticated using(is_active);
create policy brand_follows_owner_all on public.brand_follows for all to authenticated
using(private.is_active_user() and user_id=(select auth.uid()))
with check(private.is_active_user() and user_id=(select auth.uid()));
create policy user_preferences_owner_all on public.user_preferences for all to authenticated
using(private.is_active_user() and user_id=(select auth.uid()))
with check(private.is_active_user() and user_id=(select auth.uid()));
create policy reports_owner_read on public.reports for select to authenticated
using(private.is_active_user() and reporter_user_id=(select auth.uid()));
create policy reports_owner_insert on public.reports for insert to authenticated
with check(private.is_active_user() and reporter_user_id=(select auth.uid()) and status='pending' and reviewed_by is null);
create policy reports_admin_read on public.reports for select to authenticated using(private.is_admin());
create policy help_articles_public_read on public.help_articles for select to anon,authenticated using(is_published);
create policy policy_versions_public_read on public.platform_policy_versions for select to anon,authenticated using(is_active);
create policy offers_participant_read on public.offers for select to authenticated
using(private.is_active_user() and (buyer_user_id=(select auth.uid()) or private.is_seller_owner(seller_profile_id)));

grant select on public.brands,public.help_articles,public.platform_policy_versions to anon,authenticated;
grant select,insert,delete on public.brand_follows to authenticated;
grant select,insert,update,delete on public.user_preferences to authenticated;
grant select,insert on public.reports to authenticated;
grant select on public.referrals to authenticated;
grant select on public.offers to authenticated;

create or replace function private.create_offer(p_product_id uuid,p_offered_price numeric,p_expires_at timestamptz default null)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_id uuid;
begin
 if not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 select seller_id into v_seller from public.products where id=p_product_id and moderation_status='approved' and audience='public';
 if v_seller is null then raise exception 'PRODUCT_NOT_AVAILABLE'; end if;
 if private.is_seller_owner(v_seller) then raise exception 'SELF_OFFER_NOT_ALLOWED'; end if;
 if p_offered_price<=0 or p_offered_price >= (select price from public.products where id=p_product_id) then raise exception 'INVALID_OFFER_PRICE'; end if;
 insert into public.offers(product_id,seller_profile_id,buyer_user_id,offered_price,expires_at)
 values(p_product_id,v_seller,auth.uid(),p_offered_price,p_expires_at) returning id into v_id;
 return v_id;
end $$;
revoke all on function private.create_offer(uuid,numeric,timestamptz) from public,anon;
grant execute on function private.create_offer(uuid,numeric,timestamptz) to authenticated;
create function public.create_offer(p_product_id uuid,p_offered_price numeric,p_expires_at timestamptz default null)
returns uuid language sql set search_path=''
as $$ select private.create_offer($1,$2,$3) $$;
revoke all on function public.create_offer(uuid,numeric,timestamptz) from public,anon;
grant execute on function public.create_offer(uuid,numeric,timestamptz) to authenticated;

create or replace function private.respond_offer(p_offer_id uuid,p_decision text)
returns void language plpgsql security definer set search_path=''
as $$
declare v_seller uuid;
begin
 if p_decision not in ('accepted','rejected') then raise exception 'INVALID_DECISION'; end if;
 select seller_profile_id into v_seller from public.offers where id=p_offer_id and status='pending' for update;
 if v_seller is null then raise exception 'OFFER_NOT_PENDING'; end if;
 if not private.is_seller_owner(v_seller) then raise exception 'SELLER_OWNER_ONLY'; end if;
 update public.offers set status=p_decision,responded_at=now() where id=p_offer_id;
end $$;
revoke all on function private.respond_offer(uuid,text) from public,anon;
grant execute on function private.respond_offer(uuid,text) to authenticated;
create function public.respond_offer(p_offer_id uuid,p_decision text)
returns void language sql set search_path=''
as $$ select private.respond_offer($1,$2) $$;
revoke all on function public.respond_offer(uuid,text) from public,anon;
grant execute on function public.respond_offer(uuid,text) to authenticated;

create or replace function private.admin_review_report(p_report_id uuid,p_decision text,p_note text default null)
returns void language plpgsql security definer set search_path=''
as $$
declare v_old text;
begin
 if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
 if p_decision not in ('under_review','resolved','rejected') then raise exception 'INVALID_DECISION'; end if;
 select status into v_old from public.reports where id=p_report_id for update;
 if v_old is null or v_old in ('resolved','rejected') then raise exception 'REPORT_NOT_ACTIONABLE'; end if;
 update public.reports set status=p_decision,reviewed_by=auth.uid(),reviewed_at=now(),review_note=p_note where id=p_report_id;
 insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,before_data,after_data)
 values(auth.uid(),'report.reviewed','reports',p_report_id,p_note,jsonb_build_object('status',v_old),jsonb_build_object('status',p_decision));
end $$;
revoke all on function private.admin_review_report(uuid,text,text) from public,anon;
grant execute on function private.admin_review_report(uuid,text,text) to authenticated;
create function public.admin_review_report(p_report_id uuid,p_decision text,p_note text default null)
returns void language sql set search_path=''
as $$ select private.admin_review_report($1,$2,$3) $$;
revoke all on function public.admin_review_report(uuid,text,text) from public,anon;
grant execute on function public.admin_review_report(uuid,text,text) to authenticated;

create or replace function private.touch_user_preferences()
returns trigger language plpgsql set search_path=''
as $$ begin new.updated_at=now(); return new; end $$;
create trigger user_preferences_touch_updated before update on public.user_preferences
for each row execute function private.touch_user_preferences();

-- Add the new tables' foreign-key indexes; keep intentionally unused workload indexes.
create index if not exists product_view_events_viewer_fk_idx on public.product_view_events(viewer_user_id);
