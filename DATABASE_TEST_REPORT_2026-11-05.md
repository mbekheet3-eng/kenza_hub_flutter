# Kenza Hub — Database Test Run (2026-11-05)

Project: `klkcroynomxuajggqqqx`  
Branch: `feature/db-schema-alignment`  
Scope: read-only database audit and functional checks. No production-like records were created or modified.

## Results

| Check | Result |
|---|---|
| Public tables with RLS | PASS — 46/46 enabled |
| Public tables without RLS | PASS — 0 |
| Order status values | PASS — all existing values fit the allowed status check |
| Order history orphan rows | PASS — 0 |
| Dispute orphan rows | PASS — 0 |
| Evidence orphan rows | PASS — 0 |
| Evidence SHA-256 format violations | PASS — 0 |
| Dispute evidence bucket privacy | PASS — private bucket |
| Delivery service centers | PASS — exactly 6 active centers |
| Delivery radius | PASS — all 6 centers set to 5 km |
| Delivery center coordinate function checks | PASS — all 6 center points return covered |
| Invalid coordinate checks | PASS — null/out-of-range points return false |
| Catalog | PASS — 247 active categories, 30 parent groups, 30 final “Other/أخرى” categories |
| Cron jobs | PASS — 4 expected jobs active |
| Anonymous access to private schema | PASS — schema USAGE denied |
| Admin delivery review RPCs | PASS — public wrappers are SECURITY INVOKER; anon EXECUTE denied |
| RLS policies | REVIEW — 57 policies; 17 include anon, all inspected anon policies are SELECT-only (including explicit false policy on product_view_events) |
| Public SECURITY DEFINER RPCs | REVIEW — two authenticated-callable functions remain: confirm_order_agreement and advance_order_status; internal authorization checks exist |
| Auth leaked-password protection | BLOCKED — Supabase Pro feature; user previously declined upgrade |

## Cron jobs verified active

- `delivery-details-retention-daily` — daily 03:10
- `dispute-evidence-retention-daily` — daily 03:20
- `ephemeral-data-retention-60-days-daily` — daily 03:30
- `order-delivery-review-timeout-hourly` — hourly

## Important limitations / open test work

1. Orders, products, disputes, evidence, and delivery-review decision tables currently contain zero rows. Therefore buyer/seller/courier/admin end-to-end scenarios, actual image upload/download, evidence deletion, 48-hour timeout execution, and admin decision paths have NOT been exercised with fixture accounts.
2. A dedicated isolated test dataset and role-specific test accounts are needed before running mutation tests. Do not use real member data.
3. Authenticated users have USAGE on the `private` schema and EXECUTE on numerous private SECURITY DEFINER helpers/RPC implementations. Their function bodies include role/ownership checks in many cases, but this surface needs a systematic per-function authorization review and least-privilege grants before declaring the security suite fully passed.
4. Flutter RPC integration, analyzer, build, and device tests are not included in this database-only run.
5. The two public SECURITY DEFINER order RPCs are intentionally authenticated-callable and remain flagged by the Supabase advisor; they must be validated with real buyer/seller role fixtures.
6. Approximate service-center coordinates were checked mathematically only; no field/geocoding validation was performed.

## Overall status

**PARTIAL — foundational/static checks passed, but the comprehensive test suite is not closed.**  
Do not label the database fully tested until isolated role fixtures and the open security-function review are completed.
