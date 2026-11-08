-- Persistent, atomic idempotency and per-user rate limiting for Gemini calls.
create table if not exists public.product_image_review_attempts (
  id bigint generated always as identity primary key,
  requester_user_id uuid not null references public.users(id) on delete cascade,
  product_image_id uuid not null references public.product_images(id) on delete cascade,
  attempted_at timestamptz not null default now()
);
create index if not exists product_image_review_attempts_user_time_idx
  on public.product_image_review_attempts(requester_user_id,attempted_at desc);
create index if not exists product_image_review_attempts_time_idx
  on public.product_image_review_attempts(attempted_at);
alter table public.product_image_review_attempts enable row level security;
revoke all on public.product_image_review_attempts from public,anon,authenticated;
grant all on public.product_image_review_attempts to service_role;
grant usage,select on sequence public.product_image_review_attempts_id_seq to service_role;

create or replace function private.claim_product_image_review(
  p_image_id uuid,
  p_requester_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path=''
as $$
declare
  v_image public.product_images%rowtype;
  v_recent_attempts integer;
begin
  if p_requester_user_id is null or not exists (
    select 1 from public.users u
    where u.id=p_requester_user_id and u.is_active
  ) then
    raise exception 'ACTIVE_USER_REQUIRED';
  end if;

  -- Serialize claims per requester so parallel requests cannot exceed the
  -- rolling rate limit.
  perform pg_advisory_xact_lock(hashtextextended(p_requester_user_id::text, 0));

  select * into v_image
  from public.product_images
  where id=p_image_id
  for update;

  if v_image.id is null then
    raise exception 'IMAGE_NOT_FOUND';
  end if;

  -- Recover an abandoned claim after five minutes. A live request keeps the
  -- processing lease fresh only until its final status update.
  if v_image.ai_review_status='error'
     and v_image.ai_review_result->>'state'='processing'
     and nullif(v_image.ai_review_result->>'started_at','')::timestamptz
         < now() - interval '10 minutes' then
    update public.product_images
    set ai_review_status='pending',ai_review_result=null
    where id=p_image_id;
    v_image.ai_review_status := 'pending';
    v_image.ai_review_result := null;
  end if;

  if v_image.ai_review_status <> 'pending' or v_image.ai_review_result is not null then
    raise exception 'IMAGE_REVIEW_ALREADY_STARTED_OR_COMPLETED';
  end if;

  delete from public.product_image_review_attempts
  where attempted_at < now() - interval '24 hours';

  select count(*) into v_recent_attempts
  from public.product_image_review_attempts
  where requester_user_id=p_requester_user_id
    and attempted_at >= now() - interval '15 minutes';

  if v_recent_attempts >= 20 then
    raise exception 'IMAGE_REVIEW_RATE_LIMITED';
  end if;

  insert into public.product_image_review_attempts(requester_user_id,product_image_id)
  values(p_requester_user_id,p_image_id);

  update public.product_images
  set ai_review_status='error',
      ai_review_result=jsonb_build_object(
        'state','processing',
        'started_at',now()
      )
  where id=p_image_id;

  return true;
end
$$;
revoke all on function private.claim_product_image_review(uuid,uuid) from public,anon,authenticated;
grant execute on function private.claim_product_image_review(uuid,uuid) to service_role;

create or replace function public.claim_product_image_review(
  p_image_id uuid,
  p_requester_user_id uuid
)
returns boolean
language sql
security definer
set search_path=''
as $$
  select private.claim_product_image_review(p_image_id,p_requester_user_id)
$$;
revoke all on function public.claim_product_image_review(uuid,uuid) from public,anon,authenticated;
grant execute on function public.claim_product_image_review(uuid,uuid) to service_role;

-- Keep newly submitted product images private until the listing is eligible and approved.
-- Legacy objects in the public product-images bucket are intentionally not changed here.
create or replace function private.can_upload_product_image_path(p_name text,p_bucket text)
returns boolean
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_product_id uuid;
  v_user_id uuid;
begin
  if p_bucket <> 'restricted-product-images' or not private.is_active_user() then
    return false;
  end if;
  if array_length(string_to_array(p_name,'/'),1) <> 4
     or split_part(p_name,'/',1) <> 'products'
     or split_part(p_name,'/',4) = '' then
    return false;
  end if;
  begin
    v_product_id := split_part(p_name,'/',2)::uuid;
    v_user_id := split_part(p_name,'/',3)::uuid;
  exception when others then
    return false;
  end;
  return v_user_id = auth.uid()
    and private.can_manage_product_image(v_product_id);
end
$$;
revoke all on function private.can_upload_product_image_path(text,text) from public,anon;
grant execute on function private.can_upload_product_image_path(text,text) to authenticated;

create or replace function private.add_product_image(
  p_product_id uuid,
  p_image_path text,
  p_display_order integer
)
returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare
  v_id uuid;
  v_bucket text := 'restricted-product-images';
  v_expected_path text;
  v_pending_status uuid;
begin
  if not private.is_active_user() then
    raise exception 'AUTH_REQUIRED';
  end if;
  if not private.can_manage_product_image(p_product_id) then
    raise exception 'PRODUCT_IMAGE_PERMISSION_REQUIRED';
  end if;

  v_expected_path := 'products/' || p_product_id::text || '/' || auth.uid()::text || '/';
  if p_image_path not like v_expected_path || '%'
     or position('..' in p_image_path) > 0
     or array_length(string_to_array(p_image_path,'/'),1) <> 4 then
    raise exception 'INVALID_IMAGE_PATH';
  end if;
  if not exists (
    select 1 from storage.objects
    where bucket_id=v_bucket and name=p_image_path
  ) then
    raise exception 'IMAGE_OBJECT_NOT_FOUND';
  end if;

  select id into v_pending_status
  from public.product_statuses
  where slug='pending_review' and is_active;
  if v_pending_status is null then
    raise exception 'PENDING_REVIEW_STATUS_NOT_CONFIGURED';
  end if;

  insert into public.product_images(product_id,image_path,storage_bucket,display_order)
  values(p_product_id,p_image_path,v_bucket,p_display_order)
  returning id into v_id;

  -- Adding any image invalidates a previous publication until every image
  -- has passed moderation again.
  update public.products
  set moderation_status='pending',
      status_id=v_pending_status,
      published_at=null
  where id=p_product_id;

  return v_id;
end
$$;
revoke all on function private.add_product_image(uuid,text,integer) from public,anon;
grant execute on function private.add_product_image(uuid,text,integer) to authenticated;

-- A service-role-only publication gate. Gemini approval alone is insufficient:
-- seller, account, category, phone, coverage, product state and every image
-- must all still be eligible at the moment of publication.
create or replace function private.publish_product_after_ai_review(p_product_id uuid)
returns boolean
language plpgsql
security definer
set search_path=''
as $$
declare
  v_product public.products%rowtype;
  v_pending_status uuid;
  v_available_status uuid;
  v_image_count integer;
  v_unapproved_count integer;
begin
  select * into v_product
  from public.products
  where id=p_product_id
  for update;

  if v_product.id is null or v_product.moderation_status <> 'pending'
     or v_product.published_at is not null then
    return false;
  end if;

  select id into v_pending_status
  from public.product_statuses
  where slug='pending_review' and is_active;
  select id into v_available_status
  from public.product_statuses
  where slug='available' and is_active;

  if v_pending_status is null or v_available_status is null
     or v_product.status_id <> v_pending_status then
    return false;
  end if;

  if not exists (
    select 1
    from public.seller_profiles sp
    join public.users u on u.id=sp.owner_user_id
    join auth.users au on au.id=u.id
    where sp.id=v_product.seller_id
      and sp.is_active
      and u.is_active
      and au.phone_confirmed_at is not null
  ) then
    return false;
  end if;

  if not exists (
    select 1 from public.categories c
    where c.id=v_product.category_id and c.is_active
  ) then
    return false;
  end if;

  if not private.is_seller_in_service_area(v_product.seller_id) then
    return false;
  end if;

  select count(*),
         count(*) filter (where pi.ai_review_status <> 'approved')
  into v_image_count,v_unapproved_count
  from public.product_images pi
  where pi.product_id=p_product_id;

  if v_image_count=0 or v_unapproved_count>0 then
    return false;
  end if;

  update public.products
  set moderation_status='approved',
      status_id=v_available_status,
      published_at=now()
  where id=p_product_id
    and moderation_status='pending'
    and status_id=v_pending_status
    and published_at is null;

  return found;
end
$$;
revoke all on function private.publish_product_after_ai_review(uuid) from public,anon,authenticated;
grant execute on function private.publish_product_after_ai_review(uuid) to service_role;

create or replace function public.publish_product_after_ai_review(p_product_id uuid)
returns boolean
language sql
security definer
set search_path=''
as $$
  select private.publish_product_after_ai_review(p_product_id)
$$;
revoke all on function public.publish_product_after_ai_review(uuid) from public,anon,authenticated;
grant execute on function public.publish_product_after_ai_review(uuid) to service_role;

-- Use the buyer/seller's default address coordinates when available, so
-- addresses in adjacent neighborhoods inside an active center's radius qualify.
-- If coordinates are unavailable, retain the existing explicit active-region rule.
create or replace function private.is_seller_in_service_area(p_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists (
    select 1
    from public.seller_profiles sp
    join public.users u on u.id=sp.owner_user_id
    left join public.user_addresses a
      on a.user_id=u.id
     and a.is_default=true
     and a.is_deleted=false
    where sp.id=p_profile_id
      and sp.is_active
      and u.is_active
      and case
        when a.latitude is not null and a.longitude is not null then
          public.is_delivery_location_covered(a.latitude,a.longitude)
        else exists (
          select 1
          from public.regions r
          where r.id=coalesce(a.region_id,u.default_region_id)
            and r.is_active
            and r.is_delivery_active
        )
      end
  )
$$;
revoke all on function private.is_seller_in_service_area(uuid) from public,anon,authenticated;
grant execute on function private.is_seller_in_service_area(uuid) to service_role;
