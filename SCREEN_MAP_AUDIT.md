# Kenza Hub — Screen Map Audit

**Audit branch:** `feature/db-schema-alignment`  
**Scope:** Compare the approved 98-item product screen map with the Flutter source and GoRouter configuration.  
**Important:** This is a source inspection, not a runtime or device test. No APK/build was run.

## Confirmed route coverage

The current router registers 25 routes:
- Splash, Welcome, Home
- Login, Sign-up, Forgot Password, Reset Password, Auth callback
- Product details, Cart, Checkout, Order confirmation, Order tracking, Order history
- Seller dashboard, Profile, Edit Profile, My Products, About Kenza, Policies, Settings, Dispute Evidence
- Categories/Browse and Search

Several product-map items are states or components inside a screen rather than separate routes.

## Confirmed implemented or substantially present

- Splash and Welcome screens.
- Home market feed, category strip, search field and image picker entry.
- Browse/categories hierarchy and text search.
- Search result filtering and sorting (including category, condition and price).
- Product details and favorite toggle action.
- Cart and checkout presentation; checkout explicitly disables order confirmation until the server-side agreement flow is ready.
- Product listing wizard, image selection, category/brand/details/price steps, and review before publish.
- Product upload calls the server-side `moderate-product-image` function. A listing remains pending review if moderation is unavailable; the current Flutter flow does not yet provide a complete moderation-result/rejection experience.
- My Products list, edit/delete actions.
- Profile, edit profile (including profile photo), Settings, About and Policies.
- Forgot/reset password.
- Order history for buyer and seller orders, order tracking presentation, and a dispute-evidence screen for disputed orders. Evidence upload uses the authenticated server function, calculates SHA-256 on the server, and retrieves files through five-minute signed URLs with access-request audit logging.
- Seller dashboard presentation.

## Partially implemented / needs completion

- **Visual search:** image selection works; in-app visual product search is not connected.
- **Authentication OTP:** phone verification is invoked in the first product-publish flow. The agreed sensitive purchase-side verification and a dedicated reusable OTP screen are not complete.
- **AI price suggestion:** current price step displays general pricing advice and quick price presets; no Gemini-based price recommendation is wired.
- **Image moderation:** the server function is called, but the app does not yet interpret all moderation outcomes into clear approved/rejected/pending UI states.
- **Favorites:** product-level favorite toggling exists; a dedicated saved-items list inside My Account is not confirmed.
- **Address management:** checkout can load/select addresses; a complete add/edit/delete address-management screen is not confirmed.
- **Privacy controls:** some settings exist, but the full agreed privacy-control experience is not complete.
- **Pro Seller / store:** seller dashboard exists, but it explicitly says upgrade requests and approvals are not available in-app. Store setup, public store profile and full store-management workflow are incomplete.
- **Order flow:** checkout currently blocks order creation. Buyer/seller agreement, immutable agreement confirmation, courier proof, buyer receipt confirmation, 48-hour follow-up, and the pending-admin-review decision flow are not implemented end-to-end in Flutter.
- **Order tracking:** a screen exists, but its UI says status updates depend on the approved system history; it is not proof that courier tracking and delivery confirmation are operational.
- **Edit listing:** editing is handled from My Products rather than a confirmed standalone route.
- **Listing success/rejection:** publish currently displays a SnackBar and returns Home; a dedicated result screen and clear moderation rejection screen are not confirmed.

## Missing screen families

- Public seller/store profile and a complete similar-products experience.
- Location permission and nearby-search radius interface.
- Notifications center.
- Dedicated Favorites list.
- Chat list, chat details, attachments, report/block actions. The approved Chats bottom tab is not yet implemented.
- Help Center and Contact Support workflows.
- Pro Seller upgrade application, store setup/profile/products management, employee invitation and permission screens.
- Buyer/seller agreement screens and order workflow states.
- Courier delivery proof, buyer receipt confirmation, report-issue and cancellation workflows.
- Dispute opening, dispute timeline, review and decision-result screens. Evidence upload/view is now present from a disputed order; the full dispute lifecycle is still incomplete.
- Admin dashboard and administration screens for members, listings, orders, disputes/evidence, categories, delivery regions, stores/employees, notifications and audit log.
- Dedicated admin experience in mobile and the separate web admin interface.

## Approved navigation mismatch

The Home bottom navigation now has the approved **five** items: Home, Discover, Sell, Chats and Account. My Orders is inside Account, alongside account-related actions. Favorites belong inside Account when the dedicated list is implemented. The Chats tab and route are visible, but currently lead to a temporary placeholder; the conversation list and messaging workflow are still not implemented. Cart remains available through its existing route, but is no longer a bottom-navigation item.

## Authentication bottom sheet change

The login and sign-up forms have been consolidated into a reusable slide-up component at:

- `lib/screens/auth/auth_bottom_sheet.dart`

The Welcome actions now open the login or sign-up mode as a modal bottom sheet. The `/login` and `/sign-up` fallback routes also open the same sheet over the guest Home screen, so authentication-required actions do not send guests to a full-page form.

The sheet retains:
- Email/password sign-in and account creation through the existing `AuthProvider`.
- Name, email, password and confirmation validation for sign-up.
- Terms acceptance for sign-up and social registration.
- Google and Apple sign-in actions.
- Forgot-password navigation.
- Loading and error feedback.
- Guest browsing.

## Verification limits / next work

- No Flutter build, analyzer, emulator or device test was run because the database-first workflow remains in effect and APK/build work is deferred.
- The bottom sheet needs a real-device check for keyboard resizing, drag behavior, Android back handling and OAuth return.
- Existing standalone `LoginScreen` and `SignUpScreen` source files remain for compatibility, but the current router and Welcome entry actions now use the shared bottom sheet.
- The five-item bottom navigation and the order-history shortcut inside Account are now implemented in source. The dispute-evidence screen is wired in source but still needs analyzer and device verification.
