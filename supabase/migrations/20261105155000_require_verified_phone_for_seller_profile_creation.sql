CREATE OR REPLACE FUNCTION private.create_seller_profile(p_display_name text, p_bio text DEFAULT NULL)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
  v_profile_id uuid;
BEGIN
  IF v_user_id IS NULL OR NOT private.is_active_user() THEN
    RAISE EXCEPTION 'AUTH_REQUIRED';
  END IF;

  IF NOT private.is_current_user_phone_verified() THEN
    RAISE EXCEPTION 'PHONE_VERIFICATION_REQUIRED';
  END IF;

  IF p_display_name IS NULL OR char_length(trim(p_display_name)) NOT BETWEEN 3 AND 60 THEN
    RAISE EXCEPTION 'INVALID_DISPLAY_NAME';
  END IF;

  IF EXISTS (SELECT 1 FROM public.seller_profiles WHERE owner_user_id = v_user_id)
     OR EXISTS (SELECT 1 FROM public.seller_profile_members WHERE user_id = v_user_id AND revoked_at IS NULL) THEN
    RAISE EXCEPTION 'SELLER_PROFILE_ALREADY_EXISTS';
  END IF;

  INSERT INTO public.seller_profiles(owner_user_id, display_name, bio, seller_type, business_type)
  VALUES (v_user_id, trim(p_display_name), nullif(trim(p_bio), ''), 'seller', 'individual')
  RETURNING id INTO v_profile_id;

  INSERT INTO public.seller_profile_members(seller_profile_id, user_id, member_role, permissions)
  VALUES (
    v_profile_id,
    v_user_id,
    'owner',
    '{"products:read":true,"products:create":true,"products:update":true,"products:delete":true,"exchange:manage":false}'::jsonb
  );

  RETURN v_profile_id;
END
$function$;
