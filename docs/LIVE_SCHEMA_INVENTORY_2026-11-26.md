# Live Supabase schema inventory — 2026-11-26

**Project:** `kenza-hub-marketplace`  
**Project ref:** `mxdcfewkajwvtwtjoeia`  
**Source:** read-only catalog queries against the live project  
**Purpose:** record verified object inventory while reconciling the migration ledger

> This is an inventory, not a restorable SQL dump. It does not replace a schema-only export and must not be used as a fresh-database migration.

## Object counts

| Object | Count / state |
|---|---:|
| Live migration ledger records | 52 |
| Public tables | 23 |
| Public tables with RLS disabled | 0 |
| Public views | 3 |
| Public RLS policies | 59 |
| Public non-internal triggers | 15 |
| Public indexes | 76 |
| Public functions | 28 |
| Tables in `supabase_realtime` publication | 2 |

The three public views are all configured with `security_invoker = true`:

- `seller_public_badges`
- `seller_public_reviews`
- `seller_review_summaries`

The current `supabase_realtime` publication contains:

- `public.messages`
- `public.notifications`

## Public table policy inventory

Every public table has RLS enabled. Policy counts:

| Table | Policies |
|---|---:|
| account_roles | 1 |
| admin_accounts | 1 |
| categories | 1 |
| conversations | 2 |
| device_tokens | 1 |
| favorites | 3 |
| gender_change_requests | 3 |
| member_public_profiles | 1 |
| messages | 2 |
| notifications | 2 |
| pro_seller_requests | 1 |
| product_images | 4 |
| product_moderation | 0 |
| product_offers | 4 |
| product_orders | 5 |
| products | 4 |
| profiles | 3 |
| search_synonyms | 4 |
| seller_phone_badge_status | 1 |
| seller_public_locations | 4 |
| seller_reviews | 4 |
| seller_verifications | 4 |
| stores | 4 |

### Important note: product_moderation

`product_moderation` has RLS enabled and zero RLS policies. The existing design uses restricted table grants (revoked from `PUBLIC`, `anon`, and `authenticated`; access intended for `service_role`). This must be preserved and verified in any baseline export. Do not add a client-facing policy just to make the policy count nonzero.

## Storage buckets

| Bucket | Public | Max file size | Allowed MIME types |
|---|---:|---:|---|
| member-avatars | Yes | 5 MiB | image/jpeg, image/png, image/webp |
| product-images | No | 10 MiB | image/jpeg, image/png, image/webp |
| store-media | Yes | 10 MiB | image/jpeg, image/png, image/webp |

Storage object policies currently include owner-scoped avatar upload/update/delete, store-media owner operations, and product-image owner operations plus published-product/owner read access.

## Installed extensions

- pg_cron
- pg_net
- pg_stat_statements
- pg_trgm
- pgcrypto
- plpgsql
- supabase_vault
- uuid-ossp

## Public function inventory

- `apply_gender_change_request`
- `assign_default_buyer_role`
- `create_user_notification`
- `deactivate_device_token`
- `grant_kenza_admin`
- `guard_product_publication_with_moderation`
- `guard_profile_gender_change`
- `handle_new_user`
- `is_kenza_admin`
- `is_kenza_super_admin`
- `normalize_search_text`
- `notify_new_message`
- `notify_offer_activity`
- `notify_order_activity`
- `process_pending_product_orders`
- `register_device_token`
- `reset_product_moderation_after_image_change`
- `review_pro_seller_request`
- `revoke_kenza_admin`
- `search_products`
- `set_product_order_expiry`
- `set_seller_public_location_updated_at`
- `submit_pro_seller_request`
- `sync_member_public_profile`
- `validate_product_offer_insert`
- `validate_product_offer_status_transition`
- `validate_product_order_insert`
- `validate_product_order_status_transition`

## Next required export

Before declaring migrations reproducible, export the full live schema (without production data) from the Supabase CLI or dashboard. The export must include:

- table and column definitions, defaults, generated columns, constraints, and foreign keys;
- indexes, views, functions, triggers, and grants;
- RLS enablement, policies, and forced-RLS flags;
- Storage buckets and Storage policies;
- extensions and realtime publication membership.

Then restore that export to a disposable project/database and compare the resulting catalog against the live project. This inventory is only a checklist of what the export must cover.

## Safety

No production schema, data, migration ledger, Storage configuration, or Auth configuration was changed while collecting this inventory.
