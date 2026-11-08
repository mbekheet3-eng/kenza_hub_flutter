create or replace function private.edit_product(
 p_product_id uuid,p_category_id uuid,p_title_ar text,p_title_en text,p_description_ar text,p_description_en text,
 p_price numeric,p_condition_id uuid,p_color_id uuid,p_size_id uuid,p_brand_name text,p_weight_kg numeric,p_audience text
) returns void language plpgsql security definer set search_path=''
as $$
declare v_seller uuid; v_pending uuid; v_old_audience text;
begin
 select seller_id,audience into v_seller,v_old_audience from public.products where id=p_product_id for update;
 if v_seller is null then raise exception 'PRODUCT_NOT_FOUND'; end if;
 if not private.has_seller_permission(v_seller,'products:update') then raise exception 'PRODUCT_UPDATE_PERMISSION_REQUIRED'; end if;
 if not private.is_seller_in_service_area(v_seller) then raise exception 'OUTSIDE_DELIVERY_COVERAGE'; end if;
 if not exists(select 1 from public.categories where id=p_category_id and is_active) then raise exception 'INVALID_CATEGORY'; end if;
 if p_price<=0 or (p_weight_kg is not null and (p_weight_kg<0 or p_weight_kg>10)) then raise exception 'INVALID_PRODUCT_DATA'; end if;
 if p_audience not in ('public','followers','private') then raise exception 'INVALID_AUDIENCE'; end if;
 if v_old_audience='public' and p_audience<>'public' and exists(
   select 1 from public.product_images where product_id=p_product_id and storage_bucket='product-images'
 ) then raise exception 'AUDIENCE_CHANGE_REQUIRES_MEDIA_MIGRATION'; end if;
 select id into v_pending from public.product_statuses where slug='pending_review';
 update public.products set category_id=p_category_id,title_ar=trim(p_title_ar),title_en=nullif(trim(p_title_en),''),
   description_ar=p_description_ar,description_en=p_description_en,price=p_price,condition_id=p_condition_id,
   color_id=p_color_id,size_id=p_size_id,brand_name=nullif(trim(p_brand_name),''),weight_kg=p_weight_kg,
   audience=p_audience,moderation_status='pending',status_id=v_pending,published_at=null
 where id=p_product_id;
end $$;

create or replace function private.record_product_image_ai_review(
 p_product_image_id uuid,p_status text,p_result jsonb,p_model text
) returns void language plpgsql set search_path=''
as $$
begin
 if p_status not in ('approved','rejected','error') then raise exception 'INVALID_REVIEW_STATUS'; end if;
 if p_result is null or jsonb_typeof(p_result)<>'object' then raise exception 'INVALID_REVIEW_RESULT'; end if;
 update public.product_images set ai_review_status=p_status,ai_review_result=p_result,
   ai_reviewed_at=now(),ai_review_model=nullif(trim(p_model),'')
 where id=p_product_image_id;
 if not found then raise exception 'PRODUCT_IMAGE_NOT_FOUND'; end if;
end $$;
revoke all on function private.record_product_image_ai_review(uuid,text,jsonb,text) from public,anon,authenticated;
grant usage on schema private to service_role;
grant execute on function private.record_product_image_ai_review(uuid,text,jsonb,text) to service_role;

