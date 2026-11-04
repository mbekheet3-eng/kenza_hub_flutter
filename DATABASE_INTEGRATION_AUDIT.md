# Decision amendment — 2026-11-04

**This amendment supersedes conflicting database-closure wording in this audit.**

The user has reconfirmed that the 2026-10-31 decision to redesign the Supabase database (option 3) is active. The 2026-11-02 statements that production is structurally final and that no further migrations may be added are historical and no longer govern the redesign.

The approved sequence is: production remains read-only reference → target design → local Supabase migrations and tests → independent review → explicit approval for a specific production deployment. Work is on `feature/db-schema-alignment`; do not change `main`. No production schema/data changes, paid resources, or plan upgrades are authorized by this amendment.

The detailed current requirements and boundaries are in `DATABASE_REDESIGN_PLAN.md`. Findings below remain evidence from the read-only audit and must be revalidated against the local target before they are treated as final implementation contracts.

---

# Kenza Hub — Database / Flutter Integration Audit

Audit date: 2026-11-02
Status: production schema is the reference; Flutter adapts to it.

## Non-negotiable execution rules
- The existing Supabase production database is the approved target and is considered structurally final.
- Do not create a Supabase Development Branch (paid resource).
- Do not add tables, columns, relationships, RLS policies, functions, triggers, or migrations after database closure.
- No production schema or data changes without the user's specific approval.
- No paid services, subscriptions, payment integrations, or Supabase plan upgrades at launch.
- Flutter changes are isolated on `feature/db-schema-alignment`, based on `claude/fix-buyer-flow`; never change `main` directly.
- Order creation and payment remain disabled. OTP is intended only for final buyer/seller agreement confirmation once that workflow is approved and implemented.
- Database schema and existing Edge Functions are the source of truth. Older `DATABASE_SCHEMA.md` and `PROJECT_ROADMAP.md` are historical, not authoritative.

## Confirmed production schema
The current public schema includes users, seller_profiles, seller_profile_members, pro_seller_upgrade_requests, products, categories, product_images, product_conditions, product_colors, product_sizes, product_statuses, currencies, regions, user_addresses, orders, order_status_history, disputes, dispute_evidence, dispute_status_consents, escrow, payments, transactions, chats, messages, notifications, favorites, offers, reviews, reports, user_blocks, user_preferences, brands, brand_follows, follows, referrals, help_articles, platform_policy_versions, admin_audit_log, and product_view_events.

Important live column contracts:
- products: seller_id (seller_profiles FK), category_id, title_ar, title_en, description_ar, description_en, price, views_count, brand_id, color_id, size_id, condition_id, status_id, currency_id, audience and audience-change workflow fields.
- categories: id, name_ar, name_en, slug, icon_url, is_active, display_order, parent_id.
- product_images: id, product_id, image_url, display_order, created_at.
- users: first_name, last_name, username, role, email, phone, avatar_url, language, country, city, bio, rating, total_purchases, is_verified, is_active, deleted_at, account_type, total_followers, total_products, phone_verified, notifications_enabled, language_preference and security/account preference fields.
- seller_profiles: owner_user_id, seller_type, display_name, business_name, bio, avatar_url, phone, rating, total_sales, verification_status, subscription_plan, commission_rate, badges, is_active.
- seller_profile_members: seller_profile_id, user_id, member_role, permissions, invited_by, revoked_at.
- pro_seller_upgrade_requests: seller_profile_id, requested_business_type, status, applicant_note, reviewed_by, reviewed_at, review_note.
- user_addresses: region_id is the service-area reference; recipient_name, recipient_phone, address_line_1, address_line_2, landmark, postal_code, is_default, is_deleted.
- orders: buyer_id, seller_profile_id, product_id, status, total_amount, platform_fee, shipping_cost, address_id, currency_id, order_number, agreement_snapshot, agreement_version, buyer_confirmed_at, seller_confirmed_at, agreement_confirmed_at, quantity, agreed_unit_price, agreed_shipping_method, agreed_shipping_cost, agreed_fees and agreed_delivery_terms.
- order_status_history: previous_status, new_status, action, actor_id, actor_role, reason, metadata, created_at, is_override.

## Agreed seller/account model (2026-11-01)
- Registration is unified; no separate seller registration.
- One seller profile/store per account. No second store, including when the first is inactive, without an approved admin procedure.
- `seller-profile-create` creates the default `seller` type; no seller-type choice at registration.
- Pro Seller is a later upgrade initiated from the seller dashboard. `pro_seller` is a seller_type enum value.
- `agency` and `online_store` are business_type values / business directories within the same seller profile, not separate account or store types.
- The owner has full permissions. The owner chooses each employee's permissions from a checklist; permission templates may be offered with editable individual permissions.
- Only the owner can change/revoke employee permissions or manage membership. Employees cannot manage ownership or membership.
- Employees must not see buyer names, phone numbers, addresses, or other identifying data.
- Employee permissions must be enforced by the database, not only hidden in Flutter. Audit controls are required.
- No paid subscriptions or paid services at launch.

## Confirmed Edge Function contracts
- `seller-profile-create` is ACTIVE (version 2, verify_jwt=true). It requires an authenticated active user and `display_name` (3–60 chars), optionally accepts bio and phone, rejects an existing membership/profile, and atomically creates seller_profiles + owner membership with seller_type='seller'. The function returns seller_profile_id and owner role.
- `order-create` is ACTIVE (version 3, verify_jwt=true) but deliberately returns HTTP 503 / `ORDER_AGREEMENT_FLOW_NOT_READY` for every request. Do not call it to create orders or build a client-side bypass.
- Final OTP confirmation is intended to record both buyer and seller confirmations and their timestamps only when the complete agreement flow is ready. Until then checkout/order submission stays disabled.

## Confirmed catalogue data
- Four active top-level categories currently exist: clothes, shoes, kids, home.
- There are no child category rows in production at this audit. The app must render parent/child levels dynamically using categories.parent_id. The approved hierarchy remains: Kids Supplies (excluding clothes), Home Supplies, Clothes (men/women/kids), Shoes (men/women/kids).
- Do not insert category rows or alter production data without explicit approval.
- Reference tables contain active product conditions, colors, sizes, statuses and currencies. EGP is the only active currency.
- Product creation must resolve category_id, condition_id, status_id, currency_id and seller_profiles.id; auth user ID is never products.seller_id.
- Product image metadata belongs in product_images.display_order, not an embedded image_urls column.

## Confirmed Flutter incompatibilities
- Legacy Product model/service used user_id, title, description, category, condition, color, size, image_urls, image_paths, views, is_active and is_sold.
- SupabaseService queried those obsolete product columns and inserted product_images using `order`.
- AuthService referenced a non-existent `profiles` table. Auth trigger `handle_new_user` creates public.users using first_name/last_name/username/avatar_url from auth metadata.
- User model used non-existent display_name, location, latitude, longitude, total_reviews, products_count, followers_count and is_phone_verified columns.
- Order model/service used obsolete seller_id, amount, shipped_at, delivered_at, rating and review columns.
- CheckoutProvider contained direct order insertion, which is intentionally closed by the current RLS/Edge Function contract. Direct client order creation is now disabled in Flutter too.
- Order tracking previously simulated status changes and invented warehouse/location milestones; it must display order_status_history only.
- Checkout previously invented a flat shipping cost and 14% tax and displayed SAR. The current agreement snapshot must be the source of shipping/fees; the client must not invent them.
- product_variants is not part of the live schema; product size/color are reference IDs on products.
- Product view RPC exists; its current argument name is `p_product_id`, not `product_id`.

## Security / health findings and pending verification
- The four SECURITY DEFINER functions were inspected. Their EXECUTE grants are authenticated-only (anon cannot execute): current_user_role(), get_or_create_chat(), increment_product_views(), is_seller_profile_member(). They derive identity from auth.uid(); get_or_create_chat validates active product + matching seller + self-chat + blocks; increment_product_views requires auth, checks active product and deduplicates per product/user/day; is_seller_profile_member checks active (revoked_at IS NULL) membership only. Independent review and least-privilege recheck remain required.
- current_user_role() uses SECURITY DEFINER with search_path public; verify its effective search path and grants in independent review.
- product_view_events has RLS enabled with no direct policies; the agreed access path is the authenticated daily-deduplicated increment_product_views() function only. The function writes viewer_user_id from auth.uid() and increments views_count only for a new daily event.
- CRITICAL: chats has both the older permissive `chats_insert` policy and the newer `chats_insert_product_seller_guard`. PostgreSQL permissive policies combine with OR. The old policy contains `p.seller_id = p.seller_id` (tautology) rather than matching chats.seller_id, so the newer guard does not constrain inserts allowed by the old policy. The get_or_create_chat SECURITY DEFINER RPC does perform the product/seller match; Flutter must use that RPC only. The old policy needs an approved production security correction; do not silently alter it.
- CRITICAL: products_insert, products_update, products_delete and product_images write policies use is_seller_profile_member only. That function checks active membership, not per-permission JSON. Employees therefore pass RLS for product writes even if the owner did not grant that permission. Flutter currently blocks non-owner product writes as a temporary defense; this is not a replacement for DB enforcement.
- CRITICAL: seller_profiles_update permits any member row to update the profile, with no per-permission/owner-only restriction. seller_profile_members has no UPDATE policy for owner permission editing. The agreed owner-only employee management and permission checklist are not yet enforced by current RLS.
- CRITICAL: orders_select allows any seller_profile member to read the entire order row. This includes buyer_id, shipping_address/address_id and agreement fields. Employee privacy (no buyer name/phone/address/identifying data) is not enforced by this policy. Do not build employee order views until fixed.
- seller_profiles_select is public at row level; anon has column SELECT only for public fields and does not have phone column SELECT, but authenticated has SELECT on seller_profiles.phone. Thus any authenticated user who can select a seller profile can potentially read its phone; seller phone privacy is not resolved.
- products_select checks active status or seller membership/admin, but does not filter the audience field. Confirm whether non-public audience values can be read by unrelated authenticated/anon users; the agreed audience privacy model is not proven by this policy.
- pro_seller_upgrade_requests currently permits owner INSERT (status must be pending) and member SELECT. No UPDATE policy or approved atomic approval Edge Function is present in the current function list. Approval must update seller_type to pro_seller and preserve requested_business_type for the Agency/Online Store directory; the current seller_profiles schema has no business_type column, so the approved request record may be the only existing place to retain that value. Do not invent a new column or silently repurpose business_name.
- `seller-profile-create` source has been inspected: JWT verification, active-account check, duplicate check, and atomic seller profile + owner membership transaction are present. Flutter now invokes it only when an authenticated member first publishes a product and no seller profile exists; it never inserts seller_profiles or seller_profile_members directly.
- Orders have server-side transition validation, order-status history logging, tamper protection and immutable agreement snapshots. These controls were inspected; the order-create Edge Function nevertheless remains deliberately closed until the full agreement/OTP flow is ready.
- CRITICAL disputes gap: disputes_update currently permits either participant or admin to UPDATE the dispute row, without a column-level/transition restriction. No dispute status-transition trigger/RPC was found. The dispute_status_consents table exists but is not connected to transition enforcement. Participants must not be allowed to resolve/close disputes or set admin-only fields. This requires an approved security correction before dispute UI is built.
- dispute_evidence has a BEFORE UPDATE/DELETE append-only trigger, and RLS restricts evidence reads/inserts to participants/admin; this is a useful existing control.
- auto_close_inactive_disputes() closes disputes older than 30 days, but there is no pg_cron schedule and anon/authenticated cannot execute it; it is postgres-only. It is not an automatic workflow today.
- No deactivate-account RPC/Edge Function exists in the current public function list. Safe account deactivation remains unimplemented; do not replace it with a direct client update to users.is_active.
- Dispute state transitions, evidence access, participant consent, appeal/settlement timing, and admin overrides require final end-to-end tests.
- Leaked-password protection remains disabled as an accepted temporary exception because enabling it requires a paid plan upgrade; do not upgrade.
- The read-only `run_smoke_tests()` suite was executed. 22 of 24 checks passed; T10 and T15 failed. T10 (`products_old_varchars_removed`) fails because `products.brand` remains varchar and is maintained by `sync_product_brand_name()`; decide whether this is an intentional denormalized display cache or an unfinished removal. T15 (`storage_path_restricted`) fails because the current INSERT policy only checks bucket_id='product-images' and object name prefix `products/%`; it does not require the current user's UID folder. Do not change the database without approval.
- Storage bucket `product-images` is public, 10 MB limit, and allows JPEG/PNG/WebP. Flutter upload code now uses `products/<auth.uid>/<file>`, enforces the 10 MB limit and accepted MIME formats, and deletes uploaded objects by their full nested path. The database INSERT policy still does not enforce UID ownership in the path.
- All 4 existing public.users records currently have `default_region_id IS NULL`; the auth `handle_new_user()` trigger inserts name/email/avatar only and the Flutter signup form has no region selector. Product publication therefore cannot currently pass `validate_product_service_area()` for any of these accounts. Flutter now preflights the user's default_region_id and active region before creating a seller profile or uploading images, and displays a clear outside-coverage message. A region selection UX and approved coverage data reconciliation remain required.
- CRITICAL service-area mismatch: `validate_product_service_area()` requires the seller owner's `users.default_region_id` to reference an active region. `validate_order_service_area()` requires the buyer address region to be active. Current active regions are Cairo Downtown, Cairo South/Helwan, Cairo East/Nasr City, Cairo West/Zamalek, Giza Plateau/Haram, and Giza City/Sheikh Zayed. The user's approved internal launch coverage is Maadi, Dokki, Agouza, Mohandessin, Downtown, Manial and adjacent areas; current region flags therefore do not match the agreed delivery network (Maadi, Dokki, Agouza, Mohandessin are present but inactive; Manial is not present). A seller outside an active region cannot publish even though registration/browsing is intended nationwide. This needs a separate approved data decision; no region rows/flags were changed.
- `auto_close_inactive_disputes()` and `run_smoke_tests()` are not executable by anon or authenticated. The former is postgres-only; the latter is postgres/service_role only. This supersedes older notes that PUBLIC execution was present.
- Performance advisor reports 12 unindexed foreign keys and 3 RLS initplan warnings on reports policies. Review and document only; do not add indexes or change policies without approval.
- Do not drop indexes solely because usage statistics show them unused on a new/empty workload.

## Flutter implementation sequence
1. Schema-aligned catalogue/category reads and dynamic parent/child selector.
2. Schema-aligned product model, joined reads, seller-profile resolution and product image rows.
3. Users profile model/service against public.users; seller profile setup through seller-profile-create Edge Function.
4. Address model/service against user_addresses + regions, including deleted/default flags and service coverage.
5. Read-only order/order_status_history DTOs and UI; no order creation or status mutation until the approved server workflow is ready.
6. Read-only seller dashboard is implemented; Pro Seller request submission/approval and business directories remain disabled until the approved workflow and business-type persistence path are confirmed. Employee management remains disabled until DB permission enforcement/privacy is fixed.
7. Disputes UI only after state transition/evidence permissions are independently tested.
8. Run Flutter analyze/tests/build CI and independent AI review before proposing PR merge. No merge to main or production changes without explicit approval.

## Features deferred from database closure
- Order creation, payments, and final OTP agreement workflow.
- Pro Seller upgrade approval/persistence and Agency/Online Store directories.
- Employee permission enforcement/privacy verification.
- Auction and Pro Seller-only exchange workflows, if not already covered by the current schema.
- Final dispute workflow testing.
- Category child-row population (the app supports hierarchy, but production currently has only four root rows).

These are not permission to add migrations. Any requirement that cannot be met with the closed schema must be reported for a separate explicit decision, not implemented by silently changing production.
