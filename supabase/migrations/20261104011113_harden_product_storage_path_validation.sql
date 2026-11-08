create or replace function private.can_upload_product_image_path(p_name text,p_bucket text)
returns boolean language plpgsql stable security definer set search_path=''
as $$
declare v_product_id uuid; v_user_id uuid; v_audience text;
begin
 if not private.is_active_user() then return false; end if;
 if array_length(string_to_array(p_name,'/'),1)<>4 or split_part(p_name,'/',1)<>'products' then return false; end if;
 begin
   v_product_id:=split_part(p_name,'/',2)::uuid;
   v_user_id:=split_part(p_name,'/',3)::uuid;
 exception when others then return false;
 end;
 if v_user_id<>auth.uid() or split_part(p_name,'/',4)='' then return false; end if;
 if not private.can_manage_product_image(v_product_id) then return false; end if;
 select audience into v_audience from public.products where id=v_product_id;
 return (p_bucket='product-images' and v_audience='public')
     or (p_bucket='restricted-product-images' and v_audience in ('followers','private'));
end $$;
grant execute on function private.can_upload_product_image_path(text,text) to authenticated;

create or replace function private.can_read_product_image_path(p_name text)
returns boolean language plpgsql stable security definer set search_path=''
as $$
declare v_product_id uuid;
begin
 if array_length(string_to_array(p_name,'/'),1)<>4 or split_part(p_name,'/',1)<>'products' then return false; end if;
 begin v_product_id:=split_part(p_name,'/',2)::uuid;
 exception when others then return false;
 end;
 return private.can_read_product_image(v_product_id);
end $$;
grant execute on function private.can_read_product_image_path(text) to anon,authenticated;

drop policy if exists product_images_object_insert on storage.objects;
create policy product_images_object_insert on storage.objects for insert to authenticated
with check(private.can_upload_product_image_path(name,bucket_id));
drop policy if exists product_images_object_delete on storage.objects;
create policy product_images_object_delete on storage.objects for delete to authenticated
using(private.can_upload_product_image_path(name,bucket_id));
drop policy if exists restricted_product_images_object_read on storage.objects;
create policy restricted_product_images_object_read on storage.objects for select to anon,authenticated
using(bucket_id='restricted-product-images' and private.can_read_product_image_path(name));

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
 if p_image_path not like v_expected_path||'%' or position('..' in p_image_path)>0
   or array_length(string_to_array(p_image_path,'/'),1)<>4 then raise exception 'INVALID_IMAGE_PATH'; end if;
 if not exists(select 1 from storage.objects where bucket_id=v_bucket and name=p_image_path) then raise exception 'IMAGE_OBJECT_NOT_FOUND'; end if;
 insert into public.product_images(product_id,image_path,storage_bucket,display_order)
 values(p_product_id,p_image_path,v_bucket,p_display_order) returning id into v_id;
 return v_id;
end $$;

