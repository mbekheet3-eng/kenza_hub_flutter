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
  v_audience text;
begin
  if not private.is_active_user() then
    return false;
  end if;

  if p_bucket not in ('product-images','restricted-product-images') then
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

  if v_user_id <> auth.uid() then
    return false;
  end if;

  if not private.can_manage_product_image(v_product_id) then
    return false;
  end if;

  select audience into v_audience
  from public.products
  where id=v_product_id;

  -- New images remain in the private quarantine bucket until moderation,
  -- regardless of listing audience. Preserve legacy public uploads only
  -- for public-audience products.
  return (p_bucket='restricted-product-images')
      or (p_bucket='product-images' and v_audience='public');
end
$$;

revoke all on function private.can_upload_product_image_path(text,text) from public,anon;
grant execute on function private.can_upload_product_image_path(text,text) to authenticated;
