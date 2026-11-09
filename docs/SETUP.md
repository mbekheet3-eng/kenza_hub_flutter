# Kenza Hub — setup

## 1. Generate Flutter mobile platform scaffolding

The repository includes a manual GitHub Actions workflow named **Prepare Flutter platforms**. Run it from Actions → Prepare Flutter platforms → Run workflow. It generates the official Android and iOS scaffolding, configures the Kenza Hub application identifier and Supabase OAuth callback, resolves packages, and commits the generated platform files to `phase-1/implementation`. It does not build an APK or merge into `main`.

The workflow then runs `flutter analyze`. A failed analysis is reported in the workflow logs; it does not mean an APK was built.

## 2. Configure Supabase

Use the new Kenza Hub project only:

- Project ref: `mxdcfewkajwvtwtjoeia`
- Project URL: `https://mxdcfewkajwvtwtjoeia.supabase.co`

Get the project's publishable key from Supabase API settings. The Flutter client uses the `SUPABASE_PUBLISHABLE_KEY` build-time define. Never use a service-role or secret key in Flutter. Never use a service-role or secret key in Flutter.

Run with build-time values:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://mxdcfewkajwvtwtjoeia.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Do not commit keys to GitHub.

## 3. Google and Apple login — deferred

Google and Apple sign-in are intentionally postponed. Do not configure or test these providers in the current phase. The callback notes below are retained for the later OAuth phase.



The Flutter code must use this OAuth callback for continuity with the existing app identity:

```
com.kenza.hub://login-callback/
```

Add that exact callback to Supabase Authentication → URL Configuration → Redirect URLs.

Enable Google and Apple in Authentication → Sign In / Providers and enter the credentials supplied by their respective developer consoles. Provider credentials are intentionally not stored in this repository.

After generating the platform scaffolding in step 1:

- Android: add an intent filter for scheme `com.kenza.hub` and host `login-callback` to the main activity.
- iOS: register `com.kenza.hub` under `CFBundleURLSchemes` in Runner's `Info.plist`.
- iOS: add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` descriptions to `Info.plist`.

Google and Apple buttons are implemented, but OAuth cannot complete until provider credentials and native redirect handling are configured.

## 4. Product images

The app uses the existing private `product-images` bucket. It uploads JPEG, PNG, or WebP files (maximum 10 MiB each) and generates signed URLs for display. Do not make the bucket public.

## 5. Phase-one scope

Included: guest browsing, email/password authentication, Google and Apple OAuth entry points, password reset, profile name, product publishing, product editing/deletion, and private image storage.

Not included yet: orders, payments, messaging, favorites, seller subscriptions, store management, advanced search, automated image moderation, or APK release automation.

## 6. Android release signing (manual only)

The app keeps the legacy Android application ID `com.kenza.hub`. To install an update over the existing Android app, the release must also use the exact same original upload/signing keystore and credentials.

In the old repository, the four Actions secrets were identified by name. GitHub does not reveal saved secret values and they cannot be copied automatically between repositories. Add the same original values manually to the new repository under Settings → Secrets and variables → Actions:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Do not paste secret values into chat, source files, commits, or workflow logs. `ANDROID_KEYSTORE_BASE64` must contain the Base64 encoding of the original `.jks` file, not a newly generated keystore.

The repository has a separate **Build signed Android APK** workflow. It is manual-only (Actions → Build signed Android APK → Run workflow), restores the keystore temporarily, builds a release APK, and uploads the APK as a workflow artifact. It is not run automatically by this setup and does not merge anything into `main`.

Before distributing an update, confirm that the new `versionCode` is higher than the version currently installed on users' devices. Never generate a replacement keystore if the intention is to update the existing app.
