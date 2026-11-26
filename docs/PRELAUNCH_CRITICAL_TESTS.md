# Phase 1 — critical pre-launch verification

**Date:** 2026-11-26  
**Branch:** `phase-1/prelaunch-critical-fixes`

## Database checks completed

The following checks were executed against the `kenza-hub-marketplace` project inside transactions that were rolled back, so no test orders/offers or test notifications were retained:

- Inserted a purchase request with a deliberately incorrect client price/currency/status; the database stored the published product price, product currency, authenticated buyer, actual seller, and `pending` status.
- Verified authenticated users cannot update `agreed_price`, `buyer_id`, `seller_id`, or currency; only the `status` column remains updateable.
- Verified a buyer cannot accept their own purchase request.
- Verified seller acceptance, seller delivery confirmation, and buyer completion of a purchase request.
- Verified the buyer can cancel a pending request and cannot complete an order before the seller marks it delivered.
- Verified an active pending/accepted request blocks a duplicate request for the same buyer and product.
- Verified an offer's buyer, seller, currency, and initial status are derived by the database.
- Verified completion creates an `order_completed` notification for the seller.
- Verified the pending-order cron job is active and has successful executions.

## Manual device checks still required

1. Create/sign in with two test accounts on two physical Android devices.
2. Confirm both devices register active Android FCM tokens.
3. Send a purchase request from device A; verify device B receives the new-order push.
4. Accept from device B; verify device A receives the accepted-order push.
5. Open the buyer/seller conversation and confirm the auto-message is not duplicated.
6. Confirm receipt from device A; verify device B receives the completed-order notification.
7. Test email signup confirmation and password recovery from a fresh test account.

The database webhook and `send-push-notification` Edge Function are configured and return HTTP 200. However, recent webhook responses for the tested recipients reported zero active Android devices for those specific users, so end-to-end push delivery has not yet been proven on physical devices.

## Automated build/test result

GitHub Actions run `45860737349` on this branch completed these checks successfully:

- `flutter analyze --no-fatal-infos`
- `flutter test`
- Disposable PostgreSQL category-migration validation

No APK was generated as part of this run. Build and install a tester APK separately after the manual two-device push checks.
