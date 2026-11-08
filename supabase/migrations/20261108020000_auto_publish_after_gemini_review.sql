-- Automatically finalize product publication after Gemini has reviewed every image.
-- Clear approvals/rejections are automated; pending/error outcomes remain in the human-review queue.
-- This migration is source-only until explicitly applied to a Supabase project.

create or replace function private.finalize_product_ai_review(p_product_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_product public.products%rowtype;
  v_pending uuid;
  v_available uuid;
  v_hidden uuid;
  v_image_count integer;
  v_approved_count integer;
  v_rejected_count integer;
begin
  -- Serialize concurrent image-review completions for the same product.
  select *
    into v_product
    from public.products
   where id = p_product_id
   for update;

  if not found then
    return 'product_not_found';
  end if;

  select id into v_pending
    from public.product_statuses
   where slug = 'pending_review'
     and is_active;

  if v_pending is null then
    raise exception 'PENDING_REVIEW_STATUS_NOT_CONFIGURED';
  end if;

  -- Never let an old Gemini result republish or otherwise alter a product
  -- that has already moved out of the pending-review lifecycle.
  if v_product.moderation_status is distinct from 'pending'
     or v_product.status_id is distinct from v_pending then
    return 'not_pending';
  end if;

  select count(*),
         count(*) filter (where ai_review_status = 'approved'),
         count(*) filter (where ai_review_status = 'rejected')
    into v_image_count, v_approved_count, v_rejected_count
    from public.product_images
   where product_id = p_product_id;

  if v_image_count = 0 then
    return 'no_images';
  end if;

  -- A clear Gemini rejection keeps the listing unpublished.
  if v_rejected_count > 0 then
    select id into v_hidden
      from public.product_statuses
     where slug = 'hidden'
       and is_active;

    if v_hidden is null then
      raise exception 'HIDDEN_STATUS_NOT_CONFIGURED';
    end if;

    update public.products
       set moderation_status = 'rejected',
           status_id = v_hidden,
           published_at = null
     where id = p_product_id;

    insert into public.admin_audit_log(
      actor_user_id, action, target_table, target_id, reason, before_data, after_data
    )
    values (
      null,
      'product.gemini_rejected',
      'products',
      p_product_id,
      'Gemini detected a clear image-policy violation.',
      jsonb_build_object(
        'moderation_status', v_product.moderation_status,
        'status_id', v_product.status_id
      ),
      jsonb_build_object(
        'moderation_status', 'rejected',
        'status_id', v_hidden,
        'rejected_image_count', v_rejected_count
      )
    );

    return 'rejected';
  end if;

  -- Any pending/error image means Gemini could not reach a safe decision.
  -- Keep the listing pending so an administrator can review the exception.
  if v_approved_count <> v_image_count then
    return 'manual_review';
  end if;

  -- Revalidate publication eligibility at the moment of publication.
  if not private.is_seller_in_service_area(v_product.seller_id) then
    return 'blocked_delivery_coverage';
  end if;

  select id into v_available
    from public.product_statuses
   where slug = 'available'
     and is_active;

  if v_available is null then
    raise exception 'AVAILABLE_STATUS_NOT_CONFIGURED';
  end if;

  update public.products
     set moderation_status = 'approved',
         status_id = v_available,
         published_at = pg_catalog.now()
   where id = p_product_id;

  insert into public.admin_audit_log(
    actor_user_id, action, target_table, target_id, reason, before_data, after_data
  )
  values (
    null,
    'product.gemini_published',
    'products',
    p_product_id,
    'All product images passed Gemini automated review and product eligibility checks.',
    jsonb_build_object(
      'moderation_status', v_product.moderation_status,
      'status_id', v_product.status_id
    ),
    jsonb_build_object(
      'moderation_status', 'approved',
      'status_id', v_available,
      'approved_image_count', v_approved_count
    )
  );

  return 'published';
end;
$function$;

revoke all on function private.finalize_product_ai_review(uuid)
  from public, anon, authenticated, service_role;

-- The internal finalizer is intentionally not exposed directly through PostgREST.
-- Record one image decision and attempt product finalization under the same product-row lock.
-- This prevents a late duplicate/stale Gemini response from changing image state after publication.
create or replace function private.record_product_image_ai_review(
  p_product_image_id uuid,
  p_status text,
  p_result jsonb,
  p_model text
)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_product_id uuid;
  v_product public.products%rowtype;
  v_pending uuid;
begin
  if p_status is null or p_status not in ('pending', 'approved', 'rejected', 'error') then
    raise exception 'INVALID_REVIEW_STATUS';
  end if;

  if p_result is null or pg_catalog.jsonb_typeof(p_result) <> 'object' then
    raise exception 'INVALID_REVIEW_RESULT';
  end if;

  select product_id
    into v_product_id
    from public.product_images
   where id = p_product_image_id;

  if not found then
    raise exception 'PRODUCT_IMAGE_NOT_FOUND';
  end if;

  -- All Gemini result writes for a product serialize on the same parent row.
  select *
    into v_product
    from public.products
   where id = v_product_id
   for update;

  if not found then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  select id into v_pending
    from public.product_statuses
   where slug = 'pending_review'
     and is_active;

  if v_pending is null then
    raise exception 'PENDING_REVIEW_STATUS_NOT_CONFIGURED';
  end if;

  if v_product.moderation_status is distinct from 'pending'
     or v_product.status_id is distinct from v_pending then
    raise exception 'PRODUCT_NOT_PENDING_REVIEW';
  end if;

  update public.product_images
     set ai_review_status = p_status,
         ai_review_result = p_result,
         ai_reviewed_at = pg_catalog.now(),
         ai_review_model = nullif(pg_catalog.btrim(p_model), '')
   where id = p_product_image_id
     and product_id = v_product_id;

  if not found then
    raise exception 'PRODUCT_IMAGE_NOT_FOUND';
  end if;

  return private.finalize_product_ai_review(v_product_id);
end;
$function$;

revoke all on function private.record_product_image_ai_review(uuid, text, jsonb, text)
  from public, anon, authenticated, service_role;
grant execute on function private.record_product_image_ai_review(uuid, text, jsonb, text)
  to service_role;

-- Invoker wrapper: only service_role has EXECUTE, and it calls the guarded private RPC.
create or replace function public.record_product_image_ai_review(
  p_product_image_id uuid,
  p_status text,
  p_result jsonb,
  p_model text
)
returns text
language sql
security invoker
set search_path = ''
as $function$
  select private.record_product_image_ai_review($1, $2, $3, $4);
$function$;

revoke all on function public.record_product_image_ai_review(uuid, text, jsonb, text)
  from public, anon, authenticated;
grant execute on function public.record_product_image_ai_review(uuid, text, jsonb, text)
  to service_role;

-- Human review is an exception path. An administrator may approve pending/error
-- AI outcomes after inspecting them, but may not override a clear Gemini rejection.
create or replace function private.moderate_product(
  p_product_id uuid,
  p_decision text,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_product public.products%rowtype;
  v_pending uuid;
  v_available uuid;
  v_hidden uuid;
  v_image_count integer;
  v_rejected_count integer;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;

  if p_decision is null or p_decision not in ('approved', 'rejected', 'hidden') then
    raise exception 'INVALID_DECISION';
  end if;

  select *
    into v_product
    from public.products
   where id = p_product_id
   for update;

  if not found then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  select id into v_pending
    from public.product_statuses
   where slug = 'pending_review'
     and is_active;

  if v_pending is null then
    raise exception 'PENDING_REVIEW_STATUS_NOT_CONFIGURED';
  end if;

  if v_product.moderation_status is distinct from 'pending'
     or v_product.status_id is distinct from v_pending then
    raise exception 'PRODUCT_NOT_PENDING_REVIEW';
  end if;

  if p_decision = 'approved' then
    if not private.is_seller_in_service_area(v_product.seller_id) then
      raise exception 'SELLER_OUTSIDE_DELIVERY_COVERAGE';
    end if;

    select count(*),
           count(*) filter (where ai_review_status = 'rejected')
      into v_image_count, v_rejected_count
      from public.product_images
     where product_id = p_product_id;

    if v_image_count = 0 then
      raise exception 'IMAGE_AI_REVIEW_INCOMPLETE';
    end if;

    if v_rejected_count > 0 then
      raise exception 'GEMINI_REJECTED_IMAGE_CANNOT_BE_OVERRIDDEN';
    end if;

    -- Pending/error image outcomes are allowed here only because this is an
    -- explicit admin approval after the exceptional manual review.
    select id into v_available
      from public.product_statuses
     where slug = 'available'
       and is_active;

    if v_available is null then
      raise exception 'AVAILABLE_STATUS_NOT_CONFIGURED';
    end if;

    update public.products
       set moderation_status = 'approved',
           status_id = v_available,
           published_at = pg_catalog.now()
     where id = p_product_id;
  else
    select id into v_hidden
      from public.product_statuses
     where slug = 'hidden'
       and is_active;

    if v_hidden is null then
      raise exception 'HIDDEN_STATUS_NOT_CONFIGURED';
    end if;

    update public.products
       set moderation_status = p_decision,
           status_id = v_hidden,
           published_at = null
     where id = p_product_id;
  end if;

  insert into public.admin_audit_log(
    actor_user_id, action, target_table, target_id, reason, before_data, after_data
  )
  values (
    auth.uid(),
    'product.moderated',
    'products',
    p_product_id,
    p_reason,
    jsonb_build_object(
      'moderation_status', v_product.moderation_status,
      'status_id', v_product.status_id
    ),
    jsonb_build_object(
      'moderation_status', p_decision,
      'status_id', case when p_decision = 'approved' then v_available else v_hidden end
    )
  );
end;
$function$;

-- CREATE OR REPLACE preserves the existing function ACL; the public wrapper
-- public.moderate_product continues to delegate to this admin-guarded function.
comment on function private.finalize_product_ai_review(uuid) is
  'Service-role-only finalizer: publishes after every image is Gemini-approved, rejects clear image violations, and leaves uncertain/error results pending for human review.';
comment on function public.record_product_image_ai_review(uuid, text, jsonb, text) is
  'Service-role-only PostgREST wrapper for atomically recording a Gemini image result and finalizing the product.';
