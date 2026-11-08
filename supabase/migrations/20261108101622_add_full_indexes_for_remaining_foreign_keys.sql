-- Add complete indexes for foreign-key columns that were previously
-- covered only by partial indexes. PostgreSQL can use partial indexes only
-- when the query predicate implies the index predicate; these full indexes
-- also support FK checks and queries that include inactive/revoked rows.

CREATE INDEX IF NOT EXISTS seller_profile_members_user_id_idx
  ON public.seller_profile_members (user_id);

CREATE INDEX IF NOT EXISTS delivery_assignments_courier_user_id_idx
  ON public.delivery_assignments (courier_user_id);
