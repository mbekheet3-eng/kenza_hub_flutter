# Kenza Hub v2 — Database Execution Status

Updated: 2026-11-04

## Target
- Supabase project: `kenza-hub-v2`
- Project ref: `klkcroynomxuajggqqqx`
- Isolated new database target; no records imported from any previous database.
- The 17 applied SQL migrations are exported from the target project's migration history into `supabase/migrations/`.

## Implemented
- 44 public tables; RLS enabled on all 44; 55 public RLS policies.
- Security advisor: zero findings.
- Performance advisor: no unindexed foreign keys or other actionable findings; unused-index notices remain because the database has no application workload yet.
- Three Storage buckets: public `product-images`; private `restricted-product-images`; private `dispute-evidence`.
- Four root categories and six demographic groups (men/women/kids under clothes and shoes).
- Six approved launch delivery areas: Maadi, Dokki, Agouza, Mohandessin, Downtown Cairo, Manial.
- Auth profile trigger; seller profile creation; permission-scoped seller members; Pro Seller request/review; Agency and Online Store directory views.
- Product create/edit/archive, image metadata, audience-aware media storage, AI review status gate, moderation, and daily-deduplicated product views.
- Favorites, follows, brands, brand follows, Pro Seller-only carts, offers, auctions/bids, Pro Seller-only exchange, reviews, reports, notifications, preferences, referrals, help and policy content.
- Orders and delivery are separated. Delivery details are not directly selectable by clients; couriers can access details only for active assignments. Exceptional admin access requires a reason and is audited.
- Delivery-data retention is modeled as 60 days after delivery/closure, with legal hold during active disputes.
- Account-deactivation RPC and Edge Function.
- `order-create` deliberately returns HTTP 503 (`ORDER_AGREEMENT_FLOW_NOT_READY`); direct order inserts are not granted.

## Deployed Edge Functions
- `seller-profile-create` — active, JWT required.
- `deactivate-account` — active, JWT required.
- `order-create` — active, JWT required; intentionally disabled with HTTP 503.

## Verification
- Seller creation and owner membership tested in a rolled-back transaction.
- Permission-limited employee invitation and product creation tested in a rolled-back transaction.
- Anonymous category reads work; anonymous access to user records and sensitive identity columns is denied.
- Direct order insertion, direct delivery-detail reads, and direct product-view-event reads are denied.
- Buyer IDs on orders, bidder IDs on auctions, and seller-owner IDs are not exposed through client column grants.
- Security advisor: zero findings.
- Performance advisor: only unused-index informational notices remain; no missing FK indexes.

## Awaiting approved decisions / integrations
1. Chat message writes remain closed until the contact-data policy is chosen (reject vs redact). No choice has been silently made.
2. The delivery-retention purge function exists; the approved retention is 60 days after delivery/closure. No recurring scheduler is attached yet, and backup/restore handling still needs an approved operational design.
3. Dispute-evidence legal retention duration is not set; evidence remains in a private bucket.
4. Handling a dispute opened after the 60-day delivery-data window still needs a decision.
5. Whether `seller_profiles.phone` is a public business contact or a private personal number remains undecided; no phone field was added.
6. The layered architecture ADR remains pending formal approval.
7. AI image-review state and publication gate are present; external AI provider integration still needs a selected provider and secure credentials/configuration.
8. Detailed leaf subcategories and exact adjacent delivery areas remain to be finalized; only approved category roots/groups and six named areas are seeded.
9. Checkout/order creation remains disabled pending implementation and testing of the buyer/seller agreement and phone OTP flow. Approved auth rule: no OTP at login or on a new device; SMS OTP only at first listing or first purchase when the phone is unverified; verify a changed phone number; no repeated OTP after verification.

## Not done
- No user accounts, sellers, products, orders, courier profiles, or other business records were seeded.
- No payment gateway, escrow, or paid service was created.
- No Flutter application code was changed in this database step.
- No other database project was changed.
