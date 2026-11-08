-- Restrict product moderation to products awaiting review.
CREATE OR REPLACE FUNCTION private.moderate_product(p_product_id uuid, p_decision text, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_product public.products%rowtype;
 v_hidden uuid;
 v_pending uuid;
begin
 if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
 if p_decision is null or p_decision not in ('approved','rejected','hidden') then
   raise exception 'INVALID_DECISION';
 end if;

 select * into v_product
 from public.products
 where id=p_product_id
 for update;

 if v_product.id is null then raise exception 'PRODUCT_NOT_FOUND'; end if;

 select id into v_pending
 from public.product_statuses
 where slug='pending_review' and is_active;

 if v_pending is null then raise exception 'PENDING_REVIEW_STATUS_NOT_CONFIGURED'; end if;

 if v_product.moderation_status is distinct from 'pending'
    or v_product.status_id is distinct from v_pending then
   raise exception 'PRODUCT_NOT_PENDING_REVIEW';
 end if;

 if p_decision='approved' then
   -- Admin approval must pass the exact same seller, phone, category,
   -- delivery-coverage and all-images-approved gate as automatic publication.
   if not private.publish_product_after_ai_review(p_product_id) then
     raise exception 'PRODUCT_PUBLICATION_REQUIREMENTS_NOT_MET';
   end if;
 else
   select id into v_hidden
   from public.product_statuses
   where slug='hidden' and is_active;

   if v_hidden is null then raise exception 'HIDDEN_STATUS_NOT_CONFIGURED'; end if;

   update public.products
   set moderation_status=p_decision,status_id=v_hidden,published_at=null
   where id=p_product_id;
 end if;

 insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,before_data,after_data)
 values(auth.uid(),'product.moderated','products',p_product_id,p_reason,
  jsonb_build_object('moderation_status',v_product.moderation_status,'status_id',v_product.status_id),
  jsonb_build_object('moderation_status',p_decision));
end $function$;
