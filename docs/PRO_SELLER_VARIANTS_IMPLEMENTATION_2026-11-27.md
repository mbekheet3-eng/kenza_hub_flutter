# Pro Seller product variants and stock

**Implemented:** 2026-11-27  
**Branch:** `phase-1/prelaunch-critical-fixes`  
**Supabase project:** `kenza-hub-marketplace` (`mxdcfewkajwvtwtjoeia`)

## Product rules

- Ordinary / used listings remain single-unit products. No color, size, or quantity editor is shown to ordinary accounts.
- Active `pro_seller` accounts can enable variant inventory on a listing.
- Each row represents one color + size combination and its available quantity. Either color or size may be omitted, but not both.
- One product price applies to every variant. The server stores the order total as product price × requested quantity.
- Buyers choose a variant and quantity on the product detail page. Offers are hidden for variant listings in this first UI iteration.
- Search filters for color and size are not included.

## Database

- `products.has_variants` distinguishes inventory listings.
- `product_variants` stores product_id, color, size and non-negative quantity.
- RLS is enabled. Public/authorized readers can read variants of visible products; insert/update/delete require ownership and an active Pro Seller role.
- A database trigger prevents non-Pro Sellers from enabling variants.
- `product_orders.variant_id`, `quantity`, `variant_color` and `variant_size` store the selected option, requested count and immutable display snapshot.
- The insert trigger validates that the variant belongs to the product, that the requested quantity is available, derives buyer/seller/price/currency, and calculates total price server-side.
- On acceptance, the status-transition trigger decrements inventory with a conditional atomic update. If stock is insufficient, acceptance fails with `out_of_stock`.
- The single-unit unique index applies only when `variant_id IS NULL`; multiple accepted orders for a variant listing are allowed only while the corresponding stock remains.
- Variant deletion is restricted when any order references it. A product cannot switch between single-unit and variant mode while any order history references it.

## Flutter changes

- Product model parses variant rows and computes total available stock.
- Product queries embed variants in the existing product query.
- Pro Seller product form provides color presets (10 common colors), size suggestions, free text, and quantity rows.
- Product cards show variant combinations and total available stock.
- Product details allow choosing a color/size combination and selecting quantity with a stock-bounded stepper.
- Purchase requests send variant_id and quantity.
- Order inbox displays saved color/size and quantity; seller sees a localized out-of-stock message when acceptance fails.

## Verification performed

- Supabase migration ledger contains the variant schema, order snapshot, guard fix and RLS/index optimization migrations.
- RLS transaction test: active Pro Seller can enable variants and insert a variant row.
- Negative permission test: a non-Pro account was blocked by the database trigger when attempting to create a product with variants; the transaction left no test product behind.
- Rollback-only order test: product price 120 × quantity 2 produced order total 240; order snapshot stored black / M; accepting the order reduced stock from 3 to 1.
- Multi-buyer stock test: two different buyers each requested and had one unit accepted from the same variant; both orders were accepted and stock reduced from 3 to 1.
- Supabase security advisor did not report an RLS issue on `product_variants`; the existing `product_moderation` no-policy finding is intentional and pre-existing.
- Performance advisor no longer reports the variant/product-order foreign key as unindexed.

## Not yet verified

- Flutter analyzer and widget/unit tests.
- APK build and installation.
- End-to-end two-Android-device flow.
- Concurrent acceptance race with two real sessions.
- Replenishment/editing variants after existing order history.
- Accepted-order cancellation is not currently a supported status transition in the existing workflow; stock is decremented on acceptance and is not automatically restored by delivery/completion.

GitHub Actions runs were created for the pushes, but jobs exited immediately without allocating a runner (`runner_id = 0` and no steps), so they did not execute Flutter analysis or tests. Do not treat this branch as APK-ready until a real build and two-device verification pass.
