# Supabase migration source reconciliation

This branch reconstructs the source migration directory against the live Supabase V2 migration registry.

## Source layout
- **72 recorded migrations**: filenames use the exact live version and name; SQL is reconstructed from `supabase_migrations.schema_migrations.statements`.
- **1 intentional portability adjustment**: `20261105140421_add_special_clothing_other_subcategories.sql` keeps the reviewed stable-slug parent lookup instead of the fixed UUID present in the historical live SQL. This source-only change is deliberate and must be validated on a clean database before any deployment.
- **4 pending proposals** follow the recorded baseline and are not part of live migration history:
  1. `20261108110000_restrict_private_trigger_function_execute.sql`
  2. `20261108110001_restrict_product_moderation_to_pending_review.sql`
  3. `20261108110002_restrict_private_helper_function_execute.sql`
  4. `20261108110003_secure_product_image_lifecycle_and_radius_eligibility.sql`

## Important safety status
- This branch is a source reconciliation candidate, **not a deployment instruction**.
- No migration has been deployed by this reconciliation.
- No Edge Function, Storage bucket, Auth setting, secret, or production data was changed.
- The four pending proposals have not been applied to Supabase.
- No clean database replay, SQL lint, runtime test, Flutter RPC compatibility test, or Gemini end-to-end test has been run.
- Before deployment, review the intentional historical source adjustment and all four pending proposals, then perform a clean local/staging replay and application-level validation.
- The migration registry records executed statements, not necessarily the original comments/formatting. Reconstructed historical files therefore represent the recorded SQL, not byte-for-byte original source files.
