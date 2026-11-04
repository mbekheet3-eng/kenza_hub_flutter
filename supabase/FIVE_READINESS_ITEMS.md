# Kenza Hub — Five Remaining Readiness Items

**Target:** Supabase V2 (klkcroynomxuajggqqqx)
**Git branch:** feature/db-schema-alignment
**Updated:** 2026-11-04

This document records the five remaining readiness items and separates approved requirements from choices that are still open. It is a design/implementation contract, not evidence that production was changed.

## 1. Chat contact-data protection

**Approved requirement:** contact details must be handled server-side, not by Flutter-only validation.

**Current implementation:** message rows already have moderation states (pending_review, approved, redacted, rejected). Direct message writes are intentionally closed.

**Still blocked:** the policy choice—reject a message containing contact details, or redact the contact details before storage—has not been confirmed in the retrieved approved decisions. Do not enable message writes or choose one silently.

**Acceptance tests:** phone numbers, email addresses, social handles, URLs, and common obfuscated variants must be tested against the selected server-side policy; employees must not bypass it.

## 2. AI review of uploaded product images

**Approved requirement:** inspect every uploaded image for quality, relevance to the listing, and prohibited/explicit or otherwise unsuitable content before publication.

**Current implementation:** product-image records already store AI review status, result, model, and review timestamp. Product publication is blocked until every image has an approved review result. Public and restricted product media use separate Storage access rules.

**Still blocked:** external AI provider selection and secure provider credentials/configuration. No provider or API key is assumed. The provider adapter must return a normalized decision (approved/rejected/error), confidence/reason metadata, and model identifier. Fail closed: provider errors or pending review must never publish the product.

**Acceptance tests:** clean relevant image, blurry/low-quality image, unrelated image, explicit image, disallowed content, timeout/provider error, and attempted publication with one unreviewed image.

## 3. Delivery-data retention and evidence

**Approved requirement:** delete delivery recipient/address details 60 days after delivery or order closure, unless an active dispute requires a legal hold.

**Scope:** only the separate order_delivery_details data is eligible for this purge. Do not delete Auth identity, optional address-book entries, commercial order records, or dispute evidence under this rule.

**Current implementation:** delivery details are separated from orders; courier access is assignment-scoped; exceptional admin access is reason-bound and audited; a purge function and dispute legal-hold triggers exist.

**Required alignment:** the current migration text still uses a seven-day interval. The already-applied migration must not be edited in place. Generate a new timestamped migration with the Supabase CLI to change the interval to 60 days, then test the purge and dispute-hold transitions locally.

**Still blocked:** attach a supported recurring scheduler and document backup/restore handling so expired delivery details are not reintroduced. The legal retention period for original dispute evidence remains separate and undecided.

**Acceptance tests:** expiry at 60 days, no deletion before expiry, hold while dispute is active, retention clock after dispute resolution, idempotent repeated purge, and backup/restore exclusion of expired delivery details.

## 4. Detailed catalogue and adjacent delivery areas

**Approved structure already present:** four root categories—مستلزمات أطفال، مستلزمات المنزل، ملابس، أحذية. Clothes and Shoes each have رجالي، حريمي، أطفال groups. Kids Supplies excludes clothing. Six launch areas are seeded: المعادي، الدقي، العجوزة، المهندسين، وسط البلد، المنيل.

**Remaining work:** add detailed leaf subcategories under each approved group and add only the adjacent delivery areas explicitly selected for launch. Do not add speculative areas or duplicate existing regions. Preserve nationwide registration/browsing while applying service coverage to publication and delivery eligibility.

**Acceptance tests:** unique stable slugs, correct parent-child links, active/inactive visibility, no clothing under Kids Supplies, no duplicate region rows, and service-area eligibility for both existing and newly approved adjacent areas.

## 5. Buyer/seller agreement and phone OTP

**Approved authentication behavior:**
- Email/Google/Apple login remains as-is; no OTP at login and no OTP merely because a user signs in from a new device.
- Persistent login must survive app closure and device restart.
- SMS OTP is required only at the first product-publication attempt or first purchase attempt when the phone is not already verified.
- Once verified, do not ask for OTP on every listing or purchase.
- Changing the phone number requires verification of the new number.
- Enforce verification server-side, not only in Flutter.
- This phone-verification step does not replace password-compromise protections at login.

**Current implementation:** order agreement snapshot/confirmation fields and immutability protection exist. Order creation remains deliberately disabled (HTTP 503); direct order insertion is not granted.

**Required work:** implement the SMS verification UX and backend gates for first listing and first purchase; finish the buyer/seller agreement snapshot and mutual confirmation transitions; only then enable order creation after local tests and independent review.

**Acceptance tests:** unverified first listing blocked, verified listing allowed without repeated OTP, unverified first purchase blocked, verified first purchase proceeds to agreement confirmation, changed phone requires new verification, and order creation remains disabled until every agreement/OTP test passes.

## Execution boundary

- Work on feature/db-schema-alignment; do not modify main.
- Do not edit migrations already applied to Supabase V2; create new migrations with supabase migration new / the supported CLI workflow.
- No production SQL, Auth, Storage, scheduler, or Edge Function changes are authorized by this document.
- No credentials, tokens, or paid services may be committed or provisioned.
- Do not enable order-create until item 5 is complete and independently verified.