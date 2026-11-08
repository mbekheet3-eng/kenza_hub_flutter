-- Allow authenticated members to query their own public.users row.
-- Row-level security remains enabled; users_read_self restricts SELECT to auth.uid().
GRANT SELECT ON TABLE public.users TO authenticated;
