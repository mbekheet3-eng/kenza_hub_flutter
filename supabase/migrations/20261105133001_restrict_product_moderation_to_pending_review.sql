-- Restrict product moderation to products awaiting review.
CREATE OR REPLACE FUNCTION private.moderate_product(p_product_id uuid, p_decision text, p_reason text DEFAULT NULL::text)
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
 v_unapproved integer;
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
   if not private.is_seller_in_service_area(v_product.seller_id) then
     raise exception 'SELLER_OUTSIDE_DELIVERY_COVERAGE';
   end if;

   select count(*),count(*) filter(where ai_review_status<>'approved')
     into v_image_count,v_unapproved
   from public.product_images
   where product_id=p_product_id;

   if v_image_count=0 or v_unapproved>0 then
     raise exception 'IMAGE_AI_REVIEW_INCOMPLETE';
   end if;

   select id into v_available
   from public.product_statuses
   where slug='available' and is_active;

   if v_available is null then raise exception 'AVAILABLE_STATUS_NOT_CONFIGURED'; end if;

   update public.products
   set moderation_status='approved',status_id=v_available,published_at=now()
   where id=p_product_id;
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
