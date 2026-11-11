# Kenza Hub — setup

## 1. Generate Flutter Android platform scaffolding

The repository includes a manual GitHub Actions workflow named **Prepare Flutter platforms**. Run it from Actions → Prepare Flutter platforms → Run workflow. It prepares the Android scaffold and Supabase OAuth callback on `phase-1/implementation`. It does not build an APK or merge into `main`.

## 2. Configure Supabase

Use the new Kenza Hub project only:

- Project ref: `mxdcfewkajwvtwtjoeia`
- Project URL: `https://mxdcfewkajwvtwtjoeia.supabase.co`

The Flutter client reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from build-time defines. Never use a service-role or secret key in Flutter.

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://mxdcfewkajwvtwtjoeia.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Do not commit Supabase keys to GitHub.

## 3. Android Firebase Cloud Messaging

The Android Firebase app must use package name `com.kenza.hub` in Firebase project `kenza-hub`.

- Place its Firebase client configuration at `android/app/google-services.json`.
- The Google Services Gradle plugin is applied by the Android app module.
- Flutter initializes Firebase Core and Firebase Messaging at startup.
- Notification permission is requested after a user signs in.
- The FCM token is stored in Supabase `public.device_tokens` for the signed-in user. It is deactivated before sign-out.
- Tapping a system notification opens the in-app Notifications screen.

The Firebase client configuration is not a service-account credential. Never add a Firebase service-account private key, Supabase service-role key, or FCM server credential to Flutter or GitHub source files.

**Server sender deployed:** Supabase Edge Function `send-push-notification` is deployed with FCM HTTP v1 support. It accepts only a trusted Supabase server key, loads active Android tokens for the notification recipient, sends the notification, and deactivates unregistered tokens.

Before delivery works, complete both Dashboard steps:

1. Add Edge Function secret `FIREBASE_SERVICE_ACCOUNT_JSON` with the full JSON contents of a Firebase service-account key from Firebase project `kenza-hub`. Keep this secret only in Supabase Edge Function Secrets; never commit or share it.
2. Create a Database Webhook on `public.notifications`, event **INSERT**, targeting Edge Function `send-push-notification`, method POST. Add the Supabase service-key authentication header using the Dashboard's **Add auth header with service key** option. The function performs its own key validation.

The function is deployed with gateway JWT verification disabled only because current Supabase secret API keys are not JWTs; it validates the incoming server key against Supabase-injected server secrets itself. Never expose that key to Flutter or GitHub.

Do not send FCM messages directly from the Flutter client.

The workflow **Resolve Flutter dependencies** runs `flutter pub get` and `flutter analyze`, then commits the resolved `pubspec.lock`. It does not build an APK.

## 4. Google and Apple login

Google and Apple OAuth provider credentials and full sign-in verification remain a separate configuration task. The Android callback is:

```
com.kenza.hub://login-callback/
```

Add the exact callback to Supabase Authentication → URL Configuration → Redirect URLs before enabling provider login.

## 5. Product images

The app uses the existing private `product-images` bucket. It uploads JPEG, PNG, or WebP files (maximum 10 MiB each) and generates signed URLs for display. Do not make the bucket public.

## 6. Gemini product-image moderation

The active Supabase project uses the Edge Function `review-product-images` to review every uploaded listing image before publication.

- The function requires a signed-in member JWT and verifies that the member owns the draft product.
- It downloads the product images from the private `product-images` bucket on the server and sends them to Google Gemini 2.5 Flash using the Supabase Edge Function secret `GEMINI_API_KEY`.
- The Gemini key and Supabase service-role key are server-only. Never place either key in Flutter, GitHub source, build arguments, or client logs.
- The function records its decision in the private `product_moderation` table. Only the service role can access that table.
- A database trigger blocks publication unless the server has recorded an approved result. Changing listing title, description, category, or product images resets the approval and returns a published product to draft before another review.
- Clear prohibited content or an unmistakably unrelated image may be rejected. Uncertain cases and poor image quality must go to review/retry rather than being treated as prohibited. Service failures keep the product unpublished; there is no automatic approval fallback.

### Approved moderation policy

**Reject only clear violations**, including:
- Firearms, ammunition, weapon parts, explosives and fireworks.
- Illegal drugs and drug paraphernalia.
- Tobacco, vapes and nicotine products.
- Alcoholic beverages.
- Prescription-only or otherwise legally restricted medicines.
- Explicit pornography and adult sexual products.
- Poisons and dangerous chemicals.
- Clearly evidenced counterfeit goods, or goods explicitly advertised as counterfeit.
- Terrorist/extremist propaganda and material promoting violence or hatred.
- Protected wildlife, products made from protected species, and illegal wildlife trade.
- Unmistakably non-listing content such as pornography, graphic violence, memes, blank images or unrelated scenery/screenshots.

**Allow ordinary legal marketplace goods**, including new and used clothing, shoes, bags, furniture, home supplies, appliances, electronics, accessories, children's toys, and educational/recreational items. Brand logos, ordinary packaging, signs of use, scratches, hands, people modelling ordinary clothing, and normal home backgrounds are not violations by themselves.

**Quality is separate from prohibited content.** Blurry, dark, low-resolution, poorly framed or partially obstructed photos should be sent for review or a clearer-photo retry, not rejected as prohibited. Unfamiliar items and ambiguous evidence must go to review. Never infer theft, counterfeiting, illegality or protected-wildlife origin from suspicion alone. Do not identify people or infer personal traits.

- Product photos and the associated listing title/description are sent to Google Gemini for this review. The privacy policy now discloses this processing; legal review of Google processing terms, transfer locations and any required notices/consents is still required before public launch.

The review function is deployed with JWT verification enabled. Do not disable it.

## 7. Android release signing (manual only)

The app keeps the Android application ID `com.kenza.hub`. To install an update over an existing app, the release must use the exact same original upload/signing keystore and credentials.

Keep keystore files and credentials in protected GitHub Actions secrets only. Never paste secret values into chat, source files, commits, or workflow logs. Do not generate a replacement keystore if the intention is to update an existing installation.

APK builds remain manual-only and are not triggered by the Firebase setup workflow.
