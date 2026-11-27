revoke update on table public.products from authenticated;
grant update (id,owner_id,category_id,title,description,price,currency,status,created_at,audience,custom_category_name,search_title_normalized,search_description_normalized,search_custom_category_normalized,has_variants)
on table public.products to authenticated;
revoke all on function public.validate_product_order_status_transition() from public,anon,authenticated;