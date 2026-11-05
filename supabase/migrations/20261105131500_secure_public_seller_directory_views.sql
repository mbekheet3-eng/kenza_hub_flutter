-- Expose only the public seller directory fields through invoker-secured views.
-- The base-table RLS policy continues to restrict results to active seller profiles.
grant select (
  id,
  business_type,
  display_name,
  business_name,
  bio,
  avatar_url,
  verification_status,
  created_at
) on public.seller_profiles to anon, authenticated;

alter view public.agency_directory
  set (security_invoker = true);

alter view public.online_store_directory
  set (security_invoker = true);
