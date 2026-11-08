-- Internal-only helpers: no direct API/policy caller needs these grants.
revoke execute on function private.can_manage_product_image(uuid) from public, anon, authenticated;
revoke execute on function private.is_seller_in_service_area(uuid) from public, anon, authenticated;

-- Authenticated-only RLS / Storage policy helpers.
revoke execute on function private.is_active_user() from public, anon, authenticated;
grant execute on function private.is_active_user() to authenticated;

revoke execute on function private.is_dispute_participant(uuid) from public, anon, authenticated;
grant execute on function private.is_dispute_participant(uuid) to authenticated;

revoke execute on function private.can_upload_product_image_path(text,text) from public, anon, authenticated;
grant execute on function private.can_upload_product_image_path(text,text) to authenticated;

-- Public product-image visibility policies explicitly need both roles.
revoke execute on function private.can_read_product_image(uuid) from public, anon, authenticated;
grant execute on function private.can_read_product_image(uuid) to anon, authenticated;

revoke execute on function private.can_read_product_image_path(text) from public, anon, authenticated;
grant execute on function private.can_read_product_image_path(text) to anon, authenticated;
