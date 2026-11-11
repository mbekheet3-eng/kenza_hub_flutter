# Supabase contract — phase one

Project: `mxdcfewkajwvtwtjoeia`

## Tables

- `profiles`: one private row per Auth user; only the owner can read or update it. The full saved name and email remain private.
- `member_public_profiles`: a restricted public projection containing only the first name and avatar URL; it never contains email or the full name.
- `categories`: active categories are readable by guests and members. Every row must provide non-empty `name_ar`, `name_en`, and `name_fr`; the app selects the matching label using the member's chosen language. `id` and `slug` remain language-independent and stable.
- `products`: `owner_id`, `category_id`, `title`, `description`, `price`, `currency`, `status`, `created_at`.
- `product_images`: `product_id`, `storage_path`, `alt_text`, `sort_order`, `created_at`.

## Product publication workflow

1. Insert the product with `status = 'draft'`.
2. Upload every image to the private `product-images` bucket using:
   `{user_id}/{product_id}/{filename}`.
3. Insert the matching `product_images` rows.
4. Only after all images and rows succeed, update the product to `status = 'published'`.
5. If any step fails, remove uploaded files and delete the draft product.

This is immediate publication after a successful upload, not an admin review queue. Draft status is an internal safety state while the upload is in progress.

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

The more specialized store/agency sections and additional marketplace features remain outside phase one.

## Category hierarchy

- Categories use `parent_id` to form a tree; root categories have `parent_id = null`.
- `sort_order` controls ordering among siblings.
- Product creation requires selecting a leaf category. Selecting a parent category filters products across its descendants.
- Stable slugs are used by Flutter for category translations and category-intent search; category IDs remain unchanged.

## Category localization contract

`categories.name_ar`, `categories.name_en`, and `categories.name_fr` are required and must not be blank (enforced by database constraints). When adding a category, provide all three translations in the same insert or migration. Do not change `id` or `slug` when translating labels.

## Security

RLS is enabled on all exposed public tables. Private profile rows are owner-scoped, while the public member projection is read-only for client roles. Product writes are owner-scoped. The Auth insert trigger creates a matching profile row from the signup display-name metadata. No service-role key belongs in the Flutter client.


## Migration source files

The repository contains the source-controlled migrations for the deployed database contract and the category expansion:

- `20261108185823_create_marketplace_core_tables.sql`
- `20261108185831_optimize_core_rls_and_category_index.sql`
- `20261108185839_tighten_core_table_grants.sql`
- `20261108190009_create_private_product_images_storage.sql`
- `20261108191509_create_profile_on_signup_and_seed_core_categories.sql`
- `20261110010000_add_french_category_names.sql

The first four files are a source-controlled reconstruction of the verified deployed schema and policies. Before using them to provision another project, replay them against a clean disposable Supabase project and compare the resulting schema, RLS policies, grants, and Storage policies with this contract.
