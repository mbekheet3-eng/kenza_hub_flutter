# Reconciliation — Independent Code Gap Report vs Current Kenza Branch
**Date:** 2026-11-27  
**Compared branches:** `phase-1/implementation` (branch named in the independent report) and `phase-1/prelaunch-critical-fixes` (branch reviewed for the Kenza improvement gap audit).  
**Method:** read-only source comparison. No code, schema, data, or configuration changed.

## Key branch difference
The independent report explicitly reviewed `phase-1/implementation`. The current prelaunch branch contains later order-flow work that is not present in the reviewed implementation branch. Therefore, claims about order completion and delivery must be branch-qualified.

## Reconciled findings

| Topic | Independent report (`phase-1/implementation`) | Current prelaunch branch | Reconciled conclusion |
|---|---|---|---|
| Buyer completes order | The reviewed screen has no buyer completion action. | Buyer sees a completion action after seller marks the order delivered. | The report is accurate for implementation; outdated for prelaunch-critical-fixes. The newer flow is delivered -> buyer completed, but it does not use OTP. |
| Seller delivery confirmation | Not present in reviewed implementation screen. | Seller can mark an accepted order as delivered. | Implemented in prelaunch branch; needs two-device runtime test. |
| Duplicate requests | Report warns multiple buyers can order the same item. | Service precheck blocks a duplicate active request by the same buyer for the same product; database migration adds server-side protection. Multiple buyers may still have accepted orders on one listing. | The narrow duplicate-request bug is addressed. The single-physical-unit oversell risk remains because a listing does not have reliable stock quantity / atomic reservation semantics. |
| Order price integrity | Report says buyer device supplies order price. | Later migrations derive/validate transaction price and currency from the product at the database layer. | Report's statement is outdated for the current prelaunch branch/live migrations. Verify on live DB with tests; do not rely on client-only values. |
| Order mutation security | Report says status updates happen directly from app without server function. | Later migrations enforce allowed transitions and actor permissions through database-side rules/RLS. | Security logic has been strengthened in prelaunch branch. It is not accurate to describe the current live workflow as client-trusted; verify each policy and RPC/trigger path before expanding. |
| Offers tabs | Report says sent/received offers are combined. | Offers remain a combined list; purchase orders are separated into sent/received views. | Still a valid UX gap if separate offer tabs are desired. |
| Product image loading | Report identifies full-size network images and no cache/thumbnail strategy in ProductCard. | ProductCard still uses `Image.network` in the reviewed file. | Valid high-priority performance hypothesis. Profile home-grid/network/image decode before choosing caching or thumbnail architecture. |
| Reviews | Report says reviews display but no submission workflow tied to completed orders. | Reviewed screens still show no review submission workflow. | Valid gap. Schema uniqueness alone does not prove the app offers a genuine post-completion review flow. |
| Product fields and filters | Report says no brand/size/condition fields and no corresponding filters. | Search UI still visibly has category and price controls; no evidence of brand/size/condition filters in reviewed screen. | Likely valid gap; confirm exact live product schema and migrations before designing fields. |
| Drafts and batch listing | Report says no manual save/resume and no multi-product flow. | Product form remains a single-product flow in reviewed code; product `draft` state is used by moderation, not proof of a user-managed draft workflow. | Valid gap; keep moderation-generated draft distinct from user-saved draft. |
| Shipment tracking, disputes, image chat, quick replies, analytics, scout/shop inventory | Report says absent. | The reviewed current branch does not show these end-to-end features. | Retain as gaps pending targeted file/schema review and product decisions. |

## Corrections to the earlier gap audit
1. Make clear that the buyer completion action exists in `phase-1/prelaunch-critical-fixes` after seller delivery confirmation, but not in `phase-1/implementation`; neither branch provides OTP completion.
2. Distinguish same-buyer duplicate prevention from cross-buyer stock reservation. Current logic blocks repeat active requests by one buyer but intentionally permits multiple accepted orders per listing; this is unsafe for a unique one-piece listing unless stock/quantity or reservation is modeled.
3. Keep full-size image loading as a high-priority performance hypothesis supported by the ProductCard source, but require runtime profiling to prove it is the largest bottleneck.
4. Correct the broad claim that order pricing is client supplied for the current live workflow: later prelaunch migrations derive and protect price/currency server-side. This must be regression-tested.
5. Keep offers sent/received separation as an outstanding improvement; the current screen still combines offers.

## Recommended immediate work (no implementation authorized by this report)
1. Run an inventory/oversell scenario test: two different buyers request the same one-unit listing concurrently; define expected behavior before changing schema.
2. Profile home feed with realistic images and constrained network; record query latency, bytes transferred, decode time, frame jank, and cache hit rate.
3. Trace product schema and migrations for brand/size/condition/location before proposing a schema patch.
4. Verify review table constraints/RLS and implement a review-creation UX only after completed-order eligibility is proven server-side.
5. Recover or reconstruct missing migration history as a separately labelled baseline; do not fabricate historical migrations or treat a live schema inventory as a restorable backup.

## Safety
This reconciliation is documentation only. No production Supabase changes, no application-code changes, no paid resources, no APK, and no merge to `main`.
