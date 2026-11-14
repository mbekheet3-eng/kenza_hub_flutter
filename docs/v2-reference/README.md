# V2 migration source archive

Source project: Supabase Kenza Hub V2 (`klkcroynomxuajggqqqx`).
Target code branch: `phase-1/implementation` in `mbekheet3-eng/kenza_hub_flutter`.

These files preserve the original SQL statements from V2 migration history. They are deliberately stored under `docs/` with the `.sql.reference` suffix so they are **not executable Supabase migrations**.

**Do not copy these files into `supabase/migrations/` or apply them directly to Marketplace.** V2 and Marketplace have different schemas, image storage layouts, and moderation flows.

Initial compatibility findings:
- V2 image paths use four segments (`products/{product_id}/{user_id}/{file}`) and two buckets (`product-images`, `restricted-product-images`).
- Marketplace uses `product_images.storage_path`, `sort_order`, and one private `product-images` bucket with a different path layout.
- V2's temporary broad-access policies must not be transferred.
- V2's temporary human-review override and auto-publish-without-Gemini migration must not be transferred.
- The V2 product-edit routine depends on V2-only columns and reference tables; it is not compatible as-is.
- Any reusable intent must be redesigned against Marketplace's current schema and tested before deployment.

This archive is a preservation step only. It does not change either Supabase database or deploy any Edge Function.
