# Kenza Hub — Database / Flutter Integration Audit

Audit date: 2026-11-02

## Working rules
- Supabase production is read-only during this implementation pass.
- No production DDL, data changes, destructive operations, paid resources, or plan upgrades.
- Flutter work is isolated on `feature/db-schema-alignment`, based on `claude/fix-buyer-flow`.
- Database schema is the source of truth; do not recreate the obsolete schema described in older app documentation.

## Confirmed production schema
The current public schema includes users, seller_profiles, seller_profile_members, pro_seller_upgrade_requests, products, categories, product_images, product_conditions, product_colors, product_sizes, product_statuses, currencies, regions, user_addresses, orders, order_status_history, disputes, dispute_evidence, dispute_status_consents, escrow, payments, transactions, chats, messages, notifications, favorites, offers, reviews, reports, user_blocks, user_preferences, brands, brand_follows, follows, referrals, help_articles, platform_policy_versions, admin_audit_log, and product_view_events.

Important live column contracts:
- products: seller_id (seller_profiles FK), category_id, title_ar, title_en, description_ar, description_en, price, views_count, brand_id, color_id, size_id, condition_id, status_id, currency_id, audience and audience-change workflow fields.
- categories: id, name_ar, name_en, slug, icon_url, is_active, display_order, parent_id.
- product_images: id, product_id, image_url, display_order, created_at.
- users: first_name, last_name, username, role, email, phone, avatar_url, language, country, city, bio, rating, is_verified, is_active, account_type and account preference/security fields.
- seller_profiles: owner_user_id, seller_type, display_name, business_name, verification_status, subscription_plan, total_sales, is_active.
- seller_profile_members: seller_profile_id, user_id, member_role, permissions, invited_by, revoked_at.
- pro_seller_upgrade_requests: seller_profile_id, requested_business_type, status, applicant_note, reviewed_by, reviewed_at, review_note.
- user_addresses: region_id is the service-area reference; recipient_name, recipient_phone, address_line_1, address_line_2, landmark, postal_code, is_default, is_deleted.
- orders: buyer_id, seller_profile_id, product_id, status, total_amount, platform_fee, shipping_cost, address_id, currency_id, order_number, agreement_snapshot and agreed financial/delivery terms.

## Confirmed catalogue data
- Four active top-level categories currently exist: clothes, shoes, kids, home.
- No child categories currently exist in production. The app must support parent/child categories dynamically; requested child-category data must be reviewed and populated only through an approved database migration.
- Reference tables currently contain product conditions, colors, sizes, statuses and currencies. EGP is the active currency.
- Product creation must resolve category_id, condition_id, status_id, currency_id and seller_profiles.id; do not submit old text columns or assume auth user id equals seller profile id.

## Flutter incompatibilities confirmed
- Product model serializes obsolete fields: user_id, title, description, category, condition, color, size, image_urls, image_paths, views, is_active, is_sold.
- SupabaseService queries obsolete products columns: is_active, is_sold, title, category, user_id, views.
- product_images insert uses `order`; production column is `display_order`.
- AuthService references a non-existent `profiles` table; profile data belongs to `users`.
- CheckoutProvider still models addresses using obsolete fields and contains direct client order creation; production orders now use seller_profile_id and an agreement snapshot, and direct order insertion is intentionally closed. Keep order creation disabled until the approved transactional workflow is implemented.
- Order model and service use obsolete seller_id, amount, shipped_at, delivered_at, rating and review columns. Order status changes are guarded by database transition logic.
- The legacy DATABASE_SCHEMA.md and PROJECT_ROADMAP.md are not authoritative; update them only after code/schema contracts are completed.

## Security / health observations (read-only)
- Security advisor: product_view_events has RLS enabled with no policies (INFO); review whether it should be accessed only through the authenticated daily-view RPC.
- Security advisor: authenticated can execute current_user_role(), get_or_create_chat(), increment_product_views(), and is_seller_profile_member() as SECURITY DEFINER functions (WARN). Verify intended public API contracts and least privilege before changing grants.
- Leaked-password protection is disabled; previously deferred because it requires a higher Supabase plan. Do not upgrade the plan.
- Performance advisor reports 12 unindexed foreign keys and 3 RLS initplan warnings on reports policies. It also reports many unused indexes; do not remove indexes based only on an empty/new database's usage statistics.
- Current migrations include phase 0–16 and follow-up hardening through 2026-11-01, including closing direct order insert bypass, tightening escrow/order/dispute access, and requiring authenticated member address/image writes.

## Implementation order
1. Add schema-aligned read-only catalogue models/services and dynamic category selection.
2. Replace obsolete Product serialization/query contracts with a typed database adapter and joined reads.
3. Implement seller profile and active membership resolution before product create/update.
4. Implement user profile and address services against users/user_addresses/regions.
5. Replace order DTOs with the current order/agreement/status-history schema; keep checkout submission disabled until a server-side transactional workflow is approved and available.
6. Add Pro Seller upgrade request UI and seller dashboard/agency shop membership surfaces based on existing tables.
7. Add tests and run Flutter analyze/build CI; no merge to main without review.

## Outstanding database design decisions (not applied)
- Complete requested category tree: kids supplies (excluding clothes), home supplies, clothes (men/women/kids), shoes (men/women/kids).
- Review whether agency shops / online stores require additional tables or can be fully represented by seller_profiles + seller_profile_members and a future store profile extension.
- Finalize Pro Seller eligibility, trial/upgrade rules, approval and subscription behavior.
- Review deactivate-account RPC and dispute state transitions/participant consent rules.
- Review product-view policy and RPC exposure.
- Resolve performance advisor findings after workload and index usage become meaningful.
