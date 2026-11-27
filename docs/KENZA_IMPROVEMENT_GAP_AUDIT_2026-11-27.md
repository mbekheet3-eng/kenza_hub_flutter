# Kenza Hub — Improvement Gap Audit
**Date:** 2026-11-27  
**Scope reviewed:** GitHub branch `phase-1/prelaunch-critical-fixes` and read-only inventory of live Supabase project `mxdcfewkajwvtwtjoeia`.  
**Safety:** This audit made no application-code changes, no schema/data changes, no paid-service changes, and no merge to `main`.

## Executive summary
Kenza already has meaningful foundations: multi-photo product entry (up to eight), cropping/reordering, AI-assisted product details, image moderation, text/category search, visual search, price sorting/filtering, favorites, product-linked conversations, offers/orders, delivery confirmation, seller storefronts, Pro Seller requests, and seller review structures.

The largest gaps against the improvement list are: batch listing and drafts workflow; richer structured search filters and saved searches/following; review submission and seller verification workflows; the independent shop/scout/reseller inventory model; shipment tracking and shipping coverage/quotes; image chat/replies; advanced admin/disputes/moderation controls; product-performance optimizations; and management analytics.

## Status legend
- **Present:** evidence found in current code/schema.
- **Partial:** a foundation exists, but not the full requested workflow.
- **Not found:** not found in the reviewed branch/schema; this is not proof that no external/manual process exists.
- **Needs runtime test:** code/schema suggests support, but behavior needs device or end-to-end verification.

## Gap matrix

| Area | Current evidence | Status | Gap / next step |
|---|---|---|---|
| 1. Product creation | Product form supports camera and multi-image gallery selection, crop, image removal/reordering, up to 8 photos; AI suggestions call `suggest-product-details`; image review is integrated. | Partial | No multi-product batch session or save/resume draft UX found. DB has product status `draft/published/archived` and separate moderation states, but draft persistence/reopen flow needs confirmation. Rejection reason/edit-and-resubmit UX needs review. Variant/size/color grouping not found. |
| 2. Search & discovery | Text/category search, relevance/newest/price sorting, price-range filter, visual search function, favorites. Search results paginate in 20-item pages. | Partial | Structured filters for brand, size, condition, governorate/location not found in search UI/service. Saved searches, follow seller/store, new-listing alerts, personalized recommendations, and wanted-item requests not found. |
| 3. Trust & protection | Order lifecycle includes pending/accepted/rejected/cancelled/delivered/completed/expired; seller delivery confirmation and buyer completion; seller profile shows review summaries/reviews; schema has unique review per order and optional verification records. | Partial | Review submission workflow not found in reviewed screens. Identity/store verification request and review UI not found. Disputes/cases and admin conversation access scoped to a case not found. Product condition/defect evidence history and buyer-facing cancellation/return policy workflow need review. OTP handoff not found. |
| 4. Shops & independent scouts | Store types and Pro Seller request/approval exist; store owner can edit name/description/logo/banner; storefront lists seller products. | Partial / strategic gap | No shop-to-scout relationship, unique per-piece inventory code, stock reservation/lock, wholesale/net price vs reseller sale price/margin, scout dashboard, shop dashboard, or pilot attribution model found. This should be a separate pilot design, not mixed into launch-critical fixes. |
| 5. Pro Seller | Pro Seller request/approval, store profile, logo/banner, store directory and storefront exist. | Partial | No multiple store staff/users, stock/inventory dashboard, detailed analytics, paid promotion, tiered subscriptions, or local radius-based free shop discovery found. |
| 6. Shipping & orders | Order status lifecycle and in-app seller-delivered / buyer-completed steps exist. | Partial | No shipment entity/tracking timeline, carrier events, delivery ETA/price quote, coverage check at checkout, proof-of-handoff attachment, or per-zone shipping/return cost reporting found. |
| 7. Chat & notifications | Product-linked conversations, text messages, realtime message stream, offers/orders inbox, push-notification infrastructure and order notifications exist. | Partial | Message image attachments and quick replies not found. Seller professional conversation management is basic. Push end-to-end delivery still needs two-device testing with active FCM tokens. |
| 8. AI | Product-detail suggestion, image moderation/review, visual-product-search Edge Function exist. | Partial | AI price guidance, duplicate/suspicious listing detection, and buyer assistant not found. Keep buyer assistant deferred as the source document recommends. |
| 9. Performance & technical quality | Product/search pagination exists; image moderation and RLS are present; current branch has Flutter analyze/test workflow and prelaunch tests. | Needs runtime test / Partial | ProductCard and several screens use direct `Image.network`; no confirmed image cache/thumbnail/CDN strategy found in reviewed code. User-reported slow home grid needs profiling before selecting a fix. Error/performance telemetry not confirmed. |
| 10. Metrics & growth | No management analytics dashboard or event/KPI pipeline found in reviewed app files/schema inventory. | Not found | Add event definitions and a minimal internal dashboard after defining trustworthy events and privacy/retention rules. Required KPIs include listing funnel, active users, requests-to-completion, cancellations/returns, acquisition cost, delivery cost, retention, seller/scout performance, and contribution margin. |

## Recommended sequencing

### Phase 0 — Verify launch-critical behavior (before adding features)
1. Profile home-grid and image loading on real Android devices with network throttling; measure first-content time, image decode/render time, query duration, and scroll jank.
2. End-to-end test product create/edit/moderation states, including rejection reason and resubmission.
3. Test order flow with two real accounts/devices, including notifications and chat handoff.
4. Verify seller reviews can only be created from a completed genuine order; confirm current RLS/trigger enforcement.
5. Verify all Arabic/English/French user-facing states and policy disclosures.

### Phase 1 — High-value current-product improvements
1. Draft save/resume and clear moderation status/reason.
2. Search filters based on actual product attributes and available data; do not add filters without reliable fields/data.
3. Review submission flow tied to completed orders.
4. Image loading optimization based on measured bottleneck.
5. Chat image attachment and quick replies only after abuse/storage controls are specified.

### Phase 2 — Merchant operations
1. Pro Seller inventory/order tools and useful store metrics.
2. Shop/scout pilot specification and a small controlled pilot, including ownership, unique item IDs, reservation expiry, margin accounting, fulfilment and returns responsibility.
3. Shipping coverage, quote, tracking and proof-of-handoff integration based on the selected carrier contract.

### Phase 3 — Advanced growth
1. Saved searches, seller/store follows and wanted-item requests.
2. Personalization, price guidance and duplicate detection after sufficient clean data exists.
3. Promotions/subscriptions and KPI dashboard after unit economics and event definitions are agreed.

## Important implementation notes
- The live database inventory shows RLS enabled on the public tables inspected. Do not add tables/policies just because a proposed feature needs them; first inspect existing schema and access model.
- Product moderation is represented separately from the product's publication status. Keep these concepts distinct in UI and analytics.
- Store profile capability should not be mistaken for stock/inventory management or the shop/scout marketplace model.
- No code or production database changes are authorized by this audit. Each proposed feature needs a short technical design, dependencies, risk, cost (including any paid service), acceptance tests, and explicit approval before implementation.
- This audit is based on one Git branch and a live public-schema inventory on 2026-11-27. Some behavior may exist in unreviewed files, backend configuration, external services, or manual operations; confirm before declaring a feature absent.
