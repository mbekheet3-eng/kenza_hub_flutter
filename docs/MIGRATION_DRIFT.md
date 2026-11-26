# Database migration drift audit

**Audited:** 2026-11-26  
**Project:** `mxdcfewkajwvtwtjoeia` (`kenza-hub-marketplace`)  
**Branch:** `phase-1/prelaunch-critical-fixes`

## Verified counts

- Live Supabase migration ledger: **52 records**.
- SQL migration files on this branch: **38 files**.
- Exact version-and-name matches: **33**.
- Live records without a matching SQL file in this branch: **15**.
- Same migration name but different version identifier: **4**.
- Repository migration file with no matching live ledger record: **1**.

These are source-control and reproducibility differences. They are **not evidence that 15 migrations or database data disappeared from the live database**.

## Live migration records without matching SQL files in this repository

- `20261109220347_marketplace_orders_offers_messaging`
- `20261109220351_tighten_order_offer_status_permissions`
- `20261109220353_enforce_valid_order_transitions`
- `20261109220359_index_marketplace_transaction_foreign_keys`
- `20261109225415_create_user_favorites`
- `20261109232206_central_notifications_and_device_tokens`
- `20261114005302_add_seller_reviews_locations_and_verification`
- `20261114005320_secure_public_seller_views`
- `20261114005332_tighten_seller_feature_write_permissions`
- `20261114005352_add_safe_phone_verified_public_badge`
- `20261114155346_create_store_media_bucket_and_owner_policies`
- `20261119143237_align_seller_categories_with_kenza_sections`
- `20261119235730_add_messages_to_realtime_publication`
- `20261120234313_fix_product_message_read_rls_for_seller`
- `20261120234758_fix_product_message_insert_rls_for_seller`

A GitHub commit-history lookup for each of these exact migration paths returned an empty history. Therefore, the original SQL files have **not** been recovered from this repository's commit history.

## Same migration name, different version in the repository

| Live database version | Repository version | Migration |
|---|---|---|
| `20261110200047` | `20261110010000` | `add_french_category_names` |
| `20261110200304` | `20261110011000` | `require_all_category_translations` |
| `20261111112248` | `20261111111800` | `add_product_image_moderation` |
| `20261113195342` | `20261113195000` | `seed_arabic_jacket_search_synonyms` |

The SQL content currently in the repository is not proven byte-for-byte identical to the SQL originally applied under the live versions. Do not simply rename these files and assume that the migration history has been reconciled.

## Repository file without a matching live ledger record

- `20261114170000_ignore_sort_order_for_image_moderation_reset.sql`

This file must be inspected against the live schema and the migration that actually introduced the behavior before deciding whether it is obsolete, already represented by another migration, or needs a new reconciliation record. Do not delete it just to make the counts match.

## Recovered and tracked in this branch

The existing live pending-order expiry migration is represented by:

- `20261126010548_pending_product_order_expiry_and_deduplication.sql`

The following new security/notification migrations were applied to the live project and added to this branch with matching version identifiers:

- `20261126162843_secure_order_offer_mutations.sql`
- `20261126162929_prevent_duplicate_active_purchase_requests.sql`
- `20261126163026_fix_order_trigger_rls_visibility.sql`
- `20261126163251_notify_seller_on_order_completion.sql`
- `20261126163328_allow_order_completed_notifications.sql`
- `20261126163559_allow_multiple_accepted_orders_per_listing.sql`
- `20261126163651_add_seller_delivery_confirmation_step.sql`
- `20261126163748_block_duplicate_requests_until_buyer_receipt.sql`

## Reconciliation decision

1. Preserve the live production database and its migration ledger as the authority for what is currently deployed.
2. Do not fabricate historical migration files or claim that reconstructed SQL is the original SQL.
3. Export a complete schema-only snapshot from the live project, including tables, columns, constraints, indexes, RLS policies, views, functions, triggers, grants, Storage buckets/policies, extensions, and publication membership.
4. Recover original SQL only from a trusted external source if one is found (for example, a developer machine backup or exported SQL history). Label any reconstructed migration as reconstructed.
5. For a clean-install path, create and test a clearly named baseline from the verified live schema on a disposable database. Keep historical ledger reconciliation separate from the baseline so the history is not falsified.
6. Resolve the four version mismatches and the one repository-only file only after comparing their actual SQL effects with the live schema.
7. Verify a fresh disposable database against the live schema contract before treating the repository as reproducible.

## Safety

**Do not run `supabase db reset`, rebuild the production database, or apply reconstructed migrations to production as part of this work.** No production schema or data changes were made during this audit.
