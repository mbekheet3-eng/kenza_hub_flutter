CREATE OR REPLACE FUNCTION private.moderate_product(
  p_product_id uuid,
  p_decision text,
  p_reason text DEFAULT NULL::text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_product public.products%rowtype;
  v_available uuid;
  v_hidden uuid;
  v_pending uuid;
  v_image_count integer;
  v_invalid_images integer;
  v_non_manual_pending integer;
begin
  if not private.is_admin() then
    raise exception 'ADMIN_ONLY';
  end if;

  if p_decision is null or p_decision not in ('approved','rejected','hidden') then
    raise exception 'INVALID_DECISION';
  end if;

  select * into v_product
  from public.products
  where id = p_product_id
  for update;

  if v_product.id is null then
    raise exception 'PRODUCT_NOT_FOUND';
  end if;

  select id into v_pending
  from public.product_statuses
  where slug = 'pending_review' and is_active;

  if v_pending is null then
    raise exception 'PENDING_REVIEW_STATUS_NOT_CONFIGURED';
  end if;

  if v_product.moderation_status is distinct from 'pending'
     or v_product.status_id is distinct from v_pending then
    raise exception 'PRODUCT_NOT_PENDING_REVIEW';
  end if;

  if p_decision = 'approved' then
    -- Preserve the existing publication-area rule; only replace the AI
    -- approval requirement with an explicit human-admin review requirement.
    if not private.is_seller_in_service_area(v_product.seller_id) then
      raise exception 'SELLER_OUTSIDE_DELIVERY_COVERAGE';
    end if;

    select
      count(*),
      count(*) filter (where ai_review_status not in ('approved','pending')),
      count(*) filter (
        where ai_review_status = 'pending'
          and coalesce(ai_review_result->>'decision','') <> 'manual_review'
      )
    into v_image_count, v_invalid_images, v_non_manual_pending
    from public.product_images
    where product_id = p_product_id;

    if v_image_count = 0 then
      raise exception 'PRODUCT_IMAGES_REQUIRED';
    end if;

    if v_invalid_images > 0 then
      raise exception 'PRODUCT_HAS_REJECTED_OR_FAILED_IMAGE';
    end if;

    if v_non_manual_pending > 0 then
      raise exception 'PRODUCT_IMAGE_MANUAL_REVIEW_REQUIRED';
    end if;

    select id into v_available
    from public.product_statuses
    where slug = 'available' and is_active;

    if v_available is null then
      raise exception 'AVAILABLE_STATUS_NOT_CONFIGURED';
    end if;

    -- Only images explicitly queued for manual review can be approved here.
    update public.product_images
    set ai_review_status = 'approved',
        ai_review_result = coalesce(ai_review_result, '{}'::jsonb) ||
          jsonb_build_object(
            'decision', 'approved',
            'admin_override', true,
            'admin_user_id', auth.uid(),
            'admin_reviewed_at', now()
          ),
        ai_reviewed_at = now(),
        ai_review_model = 'human-admin-review'
    where product_id = p_product_id
      and ai_review_status = 'pending'
      and ai_review_result->>'decision' = 'manual_review';

    update public.products
    set moderation_status = 'approved',
        status_id = v_available,
        published_at = now()
    where id = p_product_id;
  else
    select id into v_hidden
    from public.product_statuses
    where slug = 'hidden' and is_active;

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
    jsonb_build_object('moderation_status', p_decision)
  );
end;
$function$;

-- Existing failed Gemini submissions are queued for human review as well.
update public.product_images pi
set ai_review_result = coalesce(pi.ai_review_result, '{}'::jsonb) ||
      jsonb_build_object(
        'decision', 'manual_review',
        'temporary_manual_review', true,
        'reason_ar', coalesce(
          nullif(pi.ai_review_result->>'reason_ar',''),
          'بانتظار مراجعة فريق كنزة هب'
        )
      ),
    ai_reviewed_at = null,
    ai_review_model = 'temporary-manual-review'
from public.products p
where p.id = pi.product_id
  and p.moderation_status = 'pending'
  and pi.ai_review_status = 'pending';
