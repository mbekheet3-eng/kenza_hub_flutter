-- Kenza: Buyer / Pro Seller roles, Pro Seller applications, single-owner stores and Admin registry.
-- Deliberately excludes employees and sub-accounts.

create table if not exists public.admin_accounts (
 user_id uuid primary key references auth.users(id) on delete restrict,
 is_active boolean not null default true,
 is_super_admin boolean not null default false,
 granted_by uuid references auth.users(id) on delete set null,
 granted_at timestamptz not null default now()
);
create table if not exists public.account_roles (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 role text not null check(role in ('buyer','pro_seller')),
 is_active boolean not null default true,
 granted_by uuid references auth.users(id) on delete set null,
 granted_at timestamptz not null default now(),
 unique(user_id,role)
);
create table if not exists public.pro_seller_requests (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 requested_store_name text not null check(char_length(btrim(requested_store_name)) between 2 and 100),
 store_type text not null check(store_type in ('individual_seller','physical_shop','wekala_corner','online_store')),
 store_description text check(store_description is null or char_length(btrim(store_description))<=1000),
 status text not null default 'pending' check(status in ('pending','approved','rejected','withdrawn')),
 admin_note text check(admin_note is null or char_length(btrim(admin_note))<=1000),
 reviewed_by uuid references auth.users(id) on delete set null,
 reviewed_at timestamptz,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now(),
 constraint pro_seller_request_review_consistency check(
  (status='pending' and reviewed_by is null and reviewed_at is null)
  or (status<>'pending' and reviewed_by is not null and reviewed_at is not null)
 )
);
create unique index if not exists pro_seller_one_pending_request_per_user on public.pro_seller_requests(user_id) where status='pending';
create table if not exists public.stores (
 id uuid primary key default gen_random_uuid(),
 owner_id uuid not null unique references auth.users(id) on delete restrict,
 store_name text not null check(char_length(btrim(store_name)) between 2 and 100),
 store_type text not null check(store_type in ('individual_seller','physical_shop','wekala_corner','online_store')),
 description text check(description is null or char_length(btrim(description))<=1000),
 logo_url text,
 banner_url text,
 status text not null default 'active' check(status in ('active','suspended')),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists pro_seller_requests_status_created_idx on public.pro_seller_requests(status,created_at desc);
create index if not exists account_roles_user_active_idx on public.account_roles(user_id,is_active);

insert into public.account_roles(user_id,role)
select id,'buyer' from auth.users on conflict(user_id,role) do nothing;
insert into public.admin_accounts(user_id,is_active,is_super_admin,granted_by)
select id,true,true,id from auth.users where raw_app_meta_data->>'role'='admin'
order by created_at limit 1
on conflict(user_id) do update set is_active=true,is_super_admin=true;

create or replace function public.is_kenza_admin()
returns boolean language sql stable security definer set search_path=public,pg_temp
as $$ select exists(select 1 from public.admin_accounts a where a.user_id=(select auth.uid()) and a.is_active); $$;
create or replace function public.is_kenza_super_admin()
returns boolean language sql stable security definer set search_path=public,pg_temp
as $$ select exists(select 1 from public.admin_accounts a where a.user_id=(select auth.uid()) and a.is_active and a.is_super_admin); $$;
revoke all on function public.is_kenza_admin() from public,anon;
revoke all on function public.is_kenza_super_admin() from public,anon;
grant execute on function public.is_kenza_admin() to authenticated;
grant execute on function public.is_kenza_super_admin() to authenticated;

create or replace function public.assign_default_buyer_role()
returns trigger language plpgsql security definer set search_path=public,pg_temp
as $$ begin
 insert into public.account_roles(user_id,role) values(new.id,'buyer') on conflict(user_id,role) do nothing;
 return new;
end; $$;
drop trigger if exists on_auth_user_created_default_buyer on auth.users;
create trigger on_auth_user_created_default_buyer after insert on auth.users
for each row execute function public.assign_default_buyer_role();

create or replace function public.submit_pro_seller_request(p_store_name text,p_store_type text,p_store_description text default null)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $$
declare v_user_id uuid:=auth.uid(); v_request_id uuid;
begin
 if v_user_id is null then raise exception 'Authentication required'; end if;
 if char_length(btrim(coalesce(p_store_name,''))) not between 2 and 100 then raise exception 'Store name must be between 2 and 100 characters'; end if;
 if p_store_type not in ('individual_seller','physical_shop','wekala_corner','online_store') then raise exception 'Invalid store type'; end if;
 if p_store_description is not null and char_length(btrim(p_store_description))>1000 then raise exception 'Store description is too long'; end if;
 if exists(select 1 from public.account_roles where user_id=v_user_id and role='pro_seller' and is_active) then raise exception 'Account is already a Pro Seller'; end if;
 if exists(select 1 from public.stores where owner_id=v_user_id) then raise exception 'A store already exists for this account'; end if;
 insert into public.pro_seller_requests(user_id,requested_store_name,store_type,store_description)
 values(v_user_id,btrim(p_store_name),p_store_type,nullif(btrim(p_store_description),'')) returning id into v_request_id;
 return v_request_id;
end; $$;

create or replace function public.review_pro_seller_request(p_request_id uuid,p_decision text,p_admin_note text default null)
returns uuid language plpgsql security definer set search_path=public,pg_temp
as $$
declare v_admin_id uuid:=auth.uid(); v_request public.pro_seller_requests%rowtype; v_store_id uuid;
begin
 if v_admin_id is null or not public.is_kenza_admin() then raise exception 'Admin access required'; end if;
 if p_decision not in ('approved','rejected') then raise exception 'Decision must be approved or rejected'; end if;
 if p_admin_note is not null and char_length(btrim(p_admin_note))>1000 then raise exception 'Admin note is too long'; end if;
 select * into v_request from public.pro_seller_requests where id=p_request_id for update;
 if not found then raise exception 'Request not found'; end if;
 if v_request.status<>'pending' then raise exception 'Request is no longer pending'; end if;
 update public.pro_seller_requests set status=p_decision,admin_note=nullif(btrim(p_admin_note),''),reviewed_by=v_admin_id,reviewed_at=now(),updated_at=now() where id=p_request_id;
 if p_decision='approved' then
  insert into public.account_roles(user_id,role,is_active,granted_by,granted_at) values(v_request.user_id,'pro_seller',true,v_admin_id,now())
  on conflict(user_id,role) do update set is_active=true,granted_by=excluded.granted_by,granted_at=excluded.granted_at;
  insert into public.stores(owner_id,store_name,store_type,description) values(v_request.user_id,v_request.requested_store_name,v_request.store_type,v_request.store_description)
  returning id into v_store_id;
 end if;
 return v_store_id;
end; $$;

create or replace function public.grant_kenza_admin(p_user_id uuid)
returns void language plpgsql security definer set search_path=public,pg_temp
as $$ begin
 if auth.uid() is null or not public.is_kenza_super_admin() then raise exception 'Super-admin access required'; end if;
 if not exists(select 1 from auth.users where id=p_user_id) then raise exception 'User not found'; end if;
 insert into public.admin_accounts(user_id,is_active,is_super_admin,granted_by) values(p_user_id,true,false,auth.uid())
 on conflict(user_id) do update set is_active=true,is_super_admin=false,granted_by=auth.uid(),granted_at=now();
end; $$;
create or replace function public.revoke_kenza_admin(p_user_id uuid)
returns void language plpgsql security definer set search_path=public,pg_temp
as $$ begin
 if auth.uid() is null or not public.is_kenza_super_admin() then raise exception 'Super-admin access required'; end if;
 if p_user_id=auth.uid() then raise exception 'Cannot revoke the active super-admin from itself'; end if;
 update public.admin_accounts set is_active=false where user_id=p_user_id and not is_super_admin;
end; $$;

revoke all on function public.assign_default_buyer_role() from public,anon,authenticated;
revoke all on function public.submit_pro_seller_request(text,text,text) from public,anon;
revoke all on function public.review_pro_seller_request(uuid,text,text) from public,anon;
revoke all on function public.grant_kenza_admin(uuid) from public,anon;
revoke all on function public.revoke_kenza_admin(uuid) from public,anon;
grant execute on function public.submit_pro_seller_request(text,text,text) to authenticated;
grant execute on function public.review_pro_seller_request(uuid,text,text) to authenticated;
grant execute on function public.grant_kenza_admin(uuid) to authenticated;
grant execute on function public.revoke_kenza_admin(uuid) to authenticated;

alter table public.admin_accounts enable row level security;
alter table public.account_roles enable row level security;
alter table public.pro_seller_requests enable row level security;
alter table public.stores enable row level security;
create policy "Users can read own roles or admins all" on public.account_roles for select to authenticated using(user_id=(select auth.uid()) or public.is_kenza_admin());
create policy "Users can read own requests or admins all" on public.pro_seller_requests for select to authenticated using(user_id=(select auth.uid()) or public.is_kenza_admin());
create policy "Active stores public and owners or admins can read all" on public.stores for select to anon,authenticated using(status='active' or owner_id=(select auth.uid()) or public.is_kenza_admin());
create policy "Owners can update store profile" on public.stores for update to authenticated using(owner_id=(select auth.uid()) and not public.is_kenza_admin()) with check(owner_id=(select auth.uid()) and not public.is_kenza_admin());
create policy "Admins can read admin registry" on public.admin_accounts for select to authenticated using(public.is_kenza_admin());
revoke all on public.admin_accounts,public.account_roles,public.pro_seller_requests,public.stores from anon,authenticated;
grant select on public.admin_accounts,public.account_roles,public.pro_seller_requests to authenticated;
grant select on public.stores to anon,authenticated;
grant update(store_name,description,logo_url,banner_url) on public.stores to authenticated;
