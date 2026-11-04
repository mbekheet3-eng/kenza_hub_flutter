alter table public.product_images
 add column storage_bucket text not null default 'product-images'
   check(storage_bucket in ('product-images','restricted-product-images')),
 add column ai_review_status text not null default 'pending'
   check(ai_review_status in ('pending','approved','rejected','error')),
 add column ai_review_result jsonb,
 add column ai_reviewed_at timestamptz,
 add column ai_review_model text;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('restricted-product-images','restricted-product-images',false,10485760,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;

create or replace function private.can_manage_product_image(p_product_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.products p where p.id=p_product_id
  and private.has_seller_permission(p.seller_id,'products:update'))
$$;
grant execute on function private.can_manage_product_image(uuid) to authenticated;

create or replace function private.can_read_product_image(p_product_id uuid)
returns boolean language sql stable security definer set search_path=''
as $$
 select exists(select 1 from public.products p where p.id=p_product_id
  and p.moderation_status='approved'
  and (
   p.audience='public'
   or (p.audience='followers' and exists(select 1 from public.follows f
      where f.follower_user_id=(select auth.uid()) and f.followed_seller_profile_id=p.seller_id))
   or private.has_seller_permission(p.seller_id,'products:read')
  ))
$$;
grant execute on function private.can_read_product_image(uuid) to anon,authenticated;

create or replace function private.add_product_image(p_product_id uuid,p_image_path text,p_display_order integer)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid; v_audience text; v_bucket text; v_expected_path text;
begin
 if not private.is_active_user() then raise exception 'AUTH_REQUIRED'; end if;
 if not private.can_manage_product_image(p_product_id) then raise exception 'PRODUCT_IMAGE_PERMISSION_REQUIRED'; end if;
 select audience into v_audience from public.products where id=p_product_id;
 v_bucket:=case when v_audience='public' then 'product-images' else 'restricted-product-images' end;
 v_expected_path:='products/'||p_product_id::text||'/'||auth.uid()::text||'/';
 if p_image_path not like v_expected_path||'%' or p_image_path ~ '\\.\\.' then raise exception 'INVALID_IMAGE_PATH'; end if;
 if not exists(select 1 from storage.objects where bucket_id=v_bucket and name=p_image_path) then raise exception 'IMAGE_OBJECT_NOT_FOUND'; end if;
 insert into public.product_images(product_id,image_path,storage_bucket,display_order)
 values(p_product_id,p_image_path,v_bucket,p_display_order) returning id into v_id;
 return v_id;
end $$;

drop policy if exists product_images_object_insert on storage.objects;
create policy product_images_object_insert on storage.objects for insert to authenticated
with check (
 private.is_active_user() and (storage.foldername(name))[1]='products'
 and private.can_manage_product_image(((storage.foldername(name))[2])::uuid)
 and (storage.foldername(name))[3]=auth.uid()::text
 and (
   (bucket_id='product-images' and exists(select 1 from public.products p where p.id=((storage.foldername(name))[2])::uuid and p.audience='public'))
   or (bucket_id='restricted-product-images' and exists(select 1 from public.products p where p.id=((storage.foldername(name))[2])::uuid and p.audience in ('followers','private')))
 )
);
drop policy if exists product_images_object_delete on storage.objects;
create policy product_images_object_delete on storage.objects for delete to authenticated
using (
 private.is_active_user() and (storage.foldername(name))[1]='products'
 and private.can_manage_product_image(((storage.foldername(name))[2])::uuid)
 and (storage.foldername(name))[3]=auth.uid()::text
 and bucket_id in ('product-images','restricted-product-images')
);
create policy restricted_product_images_object_read on storage.objects for select to anon,authenticated
using (
 bucket_id='restricted-product-images'
 and private.can_read_product_image(((storage.foldername(name))[2])::uuid)
 and (storage.foldername(name))[1]='products'
);

drop policy if exists product_images_read on public.product_images;
create policy product_images_read on public.product_images for select to anon,authenticated
using(private.can_read_product_image(product_id));

-- Product approval cannot bypass the requested AI photo quality/safety review.
create or replace function private.moderate_product(p_product_id uuid,p_decision text,p_reason text default null)
returns void language plpgsql security definer set search_path=''
as $$
declare v_product public.products%rowtype; v_available uuid; v_hidden uuid; v_image_count integer; v_unapproved integer;
begin
 if not private.is_admin() then raise exception 'ADMIN_ONLY'; end if;
 if p_decision not in ('approved','rejected','hidden') then raise exception 'INVALID_DECISION'; end if;
 select * into v_product from public.products where id=p_product_id for update;
 if v_product.id is null then raise exception 'PRODUCT_NOT_FOUND'; end if;
 if p_decision='approved' then
   if not private.is_seller_in_service_area(v_product.seller_id) then raise exception 'SELLER_OUTSIDE_DELIVERY_COVERAGE'; end if;
   select count(*),count(*) filter(where ai_review_status<>'approved')
     into v_image_count,v_unapproved from public.product_images where product_id=p_product_id;
   if v_image_count=0 or v_unapproved>0 then raise exception 'IMAGE_AI_REVIEW_INCOMPLETE'; end if;
   select id into v_available from public.product_statuses where slug='available';
   update public.products set moderation_status='approved',status_id=v_available,published_at=now() where id=p_product_id;
 else
   select id into v_hidden from public.product_statuses where slug='hidden';
   update public.products set moderation_status=p_decision,status_id=v_hidden,published_at=null where id=p_product_id;
 end if;
 insert into public.admin_audit_log(actor_user_id,action,target_table,target_id,reason,before_data,after_data)
 values(auth.uid(),'product.moderated','products',p_product_id,p_reason,
  jsonb_build_object('moderation_status',v_product.moderation_status),
  jsonb_build_object('moderation_status',p_decision));
end $$;

