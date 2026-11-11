# Kenza Hub Marketplace

Flutter marketplace app, rebuilt for a simple and extensible phase one.

## Included

- Guest browsing of published products.
- Email/password registration and login.
- Google and Apple OAuth entry points with brand marks.
- Profile name management.
- Product creation, immediate publication after successful image upload, editing, and deletion.
- Private Supabase product-image storage with signed URLs.

## Development

Work only on `phase-1/implementation`. Do not merge into `main` without explicit approval.

See [setup instructions](docs/SETUP.md) and the [Supabase schema contract](supabase/SCHEMA.md).

The app receives Supabase URL and publishable/anon key through `--dart-define`. Never add a service-role key or provider secrets to the Flutter repository.

## Brand identity

- Mobile app display name: **Kenza**.
- Platform and website brand: **Kenza Hub**.
- Website domain: **kenzahub.com**.
- Keep the existing Android application ID `com.kenza.hub` to preserve update compatibility.
- The approved navy-and-red Kenza symbol is stored in `assets/logos/kenza_mark.png.base64` and is used by the splash screen, welcome screen, and Android launcher icon workflow.
