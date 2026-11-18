# Supabase contract — phase one

Project: `mxdcfewkajwvtwtjoeia`

## Tables

- `profiles`: one private row per Auth user; only the owner can read or update it. The full saved name and email remain private.
- `member_public_profiles`: a restricted public projection containing only the first name and avatar URL; it never contains email or the full name.
- `categories`: active categories are readable by guests and members. Every row must provide non-empty `name_ar`, `name_en`, and `name_fr`; the app selects the matching label using the member's chosen language. `id` and `slug` remain language-independent and stable.
- `products`: `owner_id`, `category_id`, `title`, `description`, `custom_category_name` (optional seller-entered type when selecting an `*-other` leaf, max 80 characters), `price`, `currency`, `status`, `created_at`.
- `product_images`: `product_id`, `storage_path`, `alt_text`, `sort_order`, `created_at`.

## Product publication workflow

1. Insert the product with `status = 'draft'`.
2. Upload every image to the private `product-images` bucket using:
   `{user_id}/{product_id}/{filename}`.
3. Insert the matching `product_images` rows.
4. Invoke the authenticated Edge Function `review-product-images` with the product ID. The function verifies the member session and product ownership, then reviews the uploaded images with Gemini 2.5 Flash using the server-only `GEMINI_API_KEY`.
5. The function records the result in the private `product_moderation` table. It changes the product to `status = 'published'` only when every image is approved.
6. Rejected or uncertain images, missing review configuration, and review-service failures do not publish the product. The draft and its uploaded images are preserved so the owner can correct the listing and submit it again.
7. If upload or image-row creation fails before moderation, the client attempts to remove uploaded files and delete the incomplete draft.

Publication is gated by the server-side moderation result; successful upload alone is never sufficient. This is automated image moderation, not an admin review queue.

## Member profiles and avatars

- Public member names are derived in the database from the first whitespace-separated part of the saved profile name.
- The private `profiles` table remains owner-readable only. A trigger synchronizes only `first_name` and `avatar_url` to `member_public_profiles`.
- The public projection is readable by guests and members; client roles have no write access to it.
- Bucket: `member-avatars` (public read, 5 MiB maximum, JPEG/PNG/WebP). Upload, replacement, and deletion are restricted to the authenticated member's own UUID folder.
- Built-in avatars are stored as `preset:<emoji>` values and do not require an uploaded file.

## Storage

- Bucket: `product-images`
- Private bucket
- Maximum file size: 10 MiB
- MIME types: JPEG, PNG, WebP
- Public users can read images only when their associated product is published.
- Owners can access their own product images.

## Categories seeded

- clothes — ملابس / Clothes / Vêtements
- shoes — أحذية / Shoes / Chaussures
- children-supplies — مستلزمات الأطفال / Children Supplies / Articles pour enfants
- home-supplies — مستلزمات المنزل / Home Supplies / Articles pour la maison
- bags-accessories — شنط وإكسسوارات / Bags & Accessories / Sacs et accessoires

The active catalog contains 225 categories across five roots and never exceeds three levels. Electronics, general sports, and general books remain future expansion categories and are not enabled.

## Category hierarchy

- Categories use `parent_id` to form a tree; root categories have `parent_id = null`.
- `sort_order` controls ordering among siblings.
- Product creation requires selecting a leaf category. Selecting a parent category filters products across its descendants.
- Every `*-other` category is a final leaf with no children. When selected, the seller must enter a custom product type in `products.custom_category_name` (1–80 characters); sellers cannot create shared categories.
- The four specialist clothing categories (uniforms, workwear, costumes, special-occasion wear) are retained and moved out from under `clothes-other` into their appropriate branches.
- Stable slugs are used by Flutter for category translations and category-intent search; category IDs remain unchanged.

## Category localization contract

`categories.name_ar`, `categories.name_en`, and `categories.name_fr` are required and must not be blank (enforced by database constraints). When adding a category, provide all three translations in the same insert or migration. Do not change `id` or `slug` when translating labels.

## Security

RLS is enabled on all exposed public tables. Private profile rows are owner-scoped, while the public member projection is read-only for client roles. Product writes are owner-scoped. The Auth insert trigger creates a matching profile row from the signup display-name metadata. No service-role key belongs in the Flutter client.


## Migration source files

The repository contains these source-controlled migrations for the current phase-one contract and category tree:

- `20261108185823_create_marketplace_core_tables.sql`
- `20261108185831_optimize_core_rls_and_category_index.sql`
- `20261108185839_tighten_core_table_grants.sql`
- `20261108190009_create_private_product_images_storage.sql`
- `20261108191509_create_profile_on_signup_and_seed_core_categories.sql`
- `20261110010000_add_french_category_names.sql`
- `20261110011000_require_all_category_translations.sql`
- `20261110233041_expand_marketplace_category_tree.sql`
- `20261110233452_fix_category_tree_sort_order.sql`
- `20261111000854_member_profile_public_fields_and_avatars.sql`
- `20261111005953_gender_audience_controls.sql`
- `20261111010027_gender_change_admin_review.sql`
- `20261111010617_tighten_gender_change_admin_permissions.sql`
- `20261111010641_optimize_gender_change_rls.sql`
- `20261111010822_enforce_gender_audience_in_existing_chats.sql`
- `20261111010854_limit_profile_updates_to_owner.sql`
- `20261113121243_add_bags_accessories_and_reorganize_clothes_other.sql`
- `20261113121424_add_custom_category_name_to_products.sql`
- `20261113121440_constrain_custom_category_name_length.sql`
- `20261113164341_add_multilingual_marketplace_search.sql`
- `20261113164421_fix_guest_search_access_and_synonym_policies.sql`

The three November 13 migrations were approved and applied to the active Supabase project `mxdcfewkajwvtwtjoeia`. The first four core migration files are a source-controlled reconstruction of the verified deployed schema and policies; before using them to provision another project, replay them against a clean disposable Supabase project and compare the resulting schema, RLS policies, grants, and Storage policies with this contract.


## Marketplace search (migration 20261113164341)

- `products` stores generated normalized search columns for title, description, and seller-entered custom category type. `categories` stores generated normalized columns for Arabic, English, and French names.
- `public.normalize_search_text(text)` normalizes Arabic alef variants, alif maksura, ta marbuta, tatweel, Arabic diacritics, Latin case, and common French accented letters. Original display fields are never modified.
- `pg_trgm` GIN indexes support partial matching on normalized product fields, category names, and active synonym aliases.
- `public.search_synonyms` stores canonical terms and aliases in Arabic, English, or French. The table starts empty; curated synonyms can be added as real search vocabulary is collected. Active aliases are readable for search; only admins (via `app_metadata.role = admin`) can manage them.
- `public.search_products(search_query, p_category_id, p_min_price, p_max_price, p_sort, p_limit, p_offset)` returns JSON containing ordered product IDs, relevance scores, `total_count`, and `has_more`. It supports category descendants, price bounds, relevance/newest/price ordering, and server-side pagination (maximum 50 rows per page).
- The RPC is `SECURITY INVOKER`; product visibility and men/women/all audience restrictions remain enforced by the existing `products` RLS policy. The RPC returns IDs and scores only; Flutter fetches product details and images through the existing RLS-protected product query.
- Guests need SELECT privilege on `profiles` for the existing product audience RLS predicate to evaluate. The `profiles` RLS policy still exposes zero profile rows to guests; authenticated members remain owner-scoped. This grant is recorded in migration `20261113164421`.
- Search location/radius, color, size, brand, and vector embeddings are not part of this phase. Do not add them without a separate data-model decision.


## Visual image search pipeline

- Edge Function `visual-product-search` was restored from the deployed source and is tracked at `supabase/functions/visual-product-search/index.ts`.
- Deployed version 7 uses Gemini only to analyze the selected JPEG/PNG/WebP image and return product search terms, a category hint, and a short description. It does not search the public web or external stores.
- Flutter sends the returned terms to `public.search_products` using the active Supabase client session. The database remains the only source of product results and enforces audience RLS.
- The Edge Function keeps `verify_jwt = true`, reads `GEMINI_API_KEY` only from server secrets, limits the encoded image payload, and applies a best-effort per-isolate request throttle. A durable distributed rate limiter remains a pre-launch hardening item.
- The camera entry on Home now offers camera or gallery selection. Flutter compresses the chosen image and displays database search results through the same search screen and pagination flow.
