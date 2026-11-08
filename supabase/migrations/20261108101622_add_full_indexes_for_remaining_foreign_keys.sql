CREATE INDEX IF NOT EXISTS seller_profile_members_user_id_idx
  ON public.seller_profile_members (user_id);

CREATE INDEX IF NOT EXISTS delivery_assignments_courier_user_id_idx
  ON public.delivery_assignments (courier_user_id);