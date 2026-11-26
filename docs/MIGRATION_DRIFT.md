# Database migration drift audit

**Audited:** 2026-11-26  
**Project:** `mxdcfewkajwvtwtjoeia` (`kenza-hub-marketplace`)  
**Branch:** `phase-1/prelaunch-critical-fixes`

## Result

The live Supabase database has 50 recorded migrations. This branch contains 36 migration files.

The live database is operating with its recorded schema; this finding is a source-control/reproducibility gap, not evidence that the live database is broken.

### Migrations missing from this repository by migration name

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

### Same migration name, different version in the repository

| Live database version | Repository version | Migration |
|---|---|---|
| `20261110200047` | `20261110010000` | `add_french_category_names` |
| `20261110200304` | `20261110011000` | `require_all_category_translations` |
| `20261111112248` | `20261111111800` | `add_product_image_moderation` |
| `20261113195342` | `20261113195000` | `seed_arabic_jacket_search_synonyms` |

## Recovered and tracked in this branch

The existing live pending-order expiry migration is now represented by:

- `20261126010548_pending_product_order_expiry_and_deduplication.sql`

The following new security/notification migrations were applied to the live project and added to this branch with matching version identifiers:

- `20261126162843_secure_order_offer_mutations.sql`
- `20261126162929_prevent_duplicate_active_purchase_requests.sql`
- `20261126163026_fix_order_trigger_rls_visibility.sql`
- `20261126163251_notify_seller_on_order_completion.sql`
- `20261126163328_allow_order_completed_notifications.sql`
- `20261126163559_allow_multiple_accepted_orders_per_listing.sql`

## Safety rule

**Do not run `supabase db reset`, rebuild the production database, or use this branch to provision a fresh production-like database until the 15 missing migrations and 4 version discrepancies are reconciled.**

The missing SQL must be recovered from a trusted source or reconstructed against the live schema and reviewed. Do not replace it with guessed SQL. The existing production database should not be reset as part of this reconciliation.
