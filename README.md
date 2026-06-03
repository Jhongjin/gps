# 곁에

`곁에` is a consent-first family and friend location sharing app concept for iOS and Android.

The product direction is simple: every safety feature stays free, and revenue comes from privacy-safe advertising that never interrupts urgent flows.

## What Is In This Workspace

- `docs/strategy.md`: market read, differentiation, monetization, launch plan.
- `docs/architecture.md`: technical architecture draft. A sub-agent may refine this file.
- `docs/design.md`: product design brief. A sub-agent may refine this file.
- `DESIGN.md`: applied visual system based on the requested design skill and markdown references.
- `docs/p0-map-implementation.md`: real-map P0 implementation plan and provider direction.
- `docs/p1-companion-mode.md`: session-based companion mode, ETA, and live route plan.
- `docs/p1-5-checkin-status.md`: check-in, arrival, battery, and stale-location behavior.
- `docs/p2-privacy-dashboard.md`: privacy dashboard controls and viewer-log plan.
- `docs/p2-place-alerts.md`: place alert conditions, radius, people, and quiet-hour plan.
- `docs/p2-5-data-and-ads.md`: user data rights and privacy-safe ad model.
- `docs/circle-invite-companion-flow.md`: invite, circle member, and companion-session product flow.
- `docs/privacy-ads-data-flow.md`: privacy dashboard, ad isolation, and data request flow.
- `docs/backend-architecture.md`: Supabase/RLS, Realtime, retention, and worker plan.
- `docs/store-review-pack.md`: App Store and Google Play review notes, disclosure copy, and data safety draft.
- `docs/ci-validation.md`: CI checks for Flutter, static strings, and Supabase migrations.
- `docs/qa.md`: QA and release checklist. A sub-agent may refine this file.
- `docs/copy.md`: naming and copy. A sub-agent may refine this file.
- `apps/gyeote_flutter/`: production Flutter app scaffold with native location bridge contracts.
- `supabase/`: Postgres schema and RLS migrations for the production backend baseline.
- `supabase/deployment-log.md`: production Supabase project application log.
- `App.tsx` and `src/`: Expo React Native MVP shell.
- `prototype/index.html`: no-build clickable web prototype for fast stakeholder review.

## Stack Direction

Production recommendation is Flutter with native iOS/Android location bridges, because this app's hardest problem is background location reliability and store-review compliance.

This workspace also includes an Expo React Native shell for fast MVP discussion. Treat it as a prototype scaffold, not a final stack lock-in. See `docs/stack-decision.md`.

The first production backend should be Supabase or Firebase, then move high-volume location ingestion to a dedicated service when usage justifies it.

## Local Setup

This machine currently does not expose working `node`, `npm`, or `git` commands in PATH, so I could not install dependencies here. On a development machine:

```bash
npm install
npx expo install --fix
npx expo start
```

For AdMob, replace the placeholder app IDs in `app.json` and keep ad SDK initialization behind the consent checks described in `docs/qa.md`.

For native builds:

```bash
npx eas build --platform ios
npx eas build --platform android
```

For the Flutter production scaffold, pass Supabase values with `--dart-define`:

```bash
cd apps/gyeote_flutter
flutter pub get
flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key>
```

When Supabase values are present, Flutter starts with the email/password login and signup gate. New accounts use the database auth trigger to create the matching profile and privacy-safe ad preference row.

The Flutter scaffold requires Dart 3.6 or newer and currently uses `flutter_map` with OpenStreetMap tiles for the keyless MVP map. The production Korea-first provider plan remains Naver Maps after the native SDK spike.

On Windows, after creating `.env.local`, use:

```powershell
.\tools\run-flutter.ps1
```

CI validation is defined in `.github/workflows/validate.yml`.

Open the web prototype directly:

```text
E:\codex\gps\prototype\index.html
```

## Current Flutter Status

Latest verified local preview:

```text
http://127.0.0.1:4174/?v=1780220654147
```

Implemented in the Flutter app:

- Supabase auth gate, circle creation/invite/accept flows, and no-circle empty states.
- Real map surface with OpenStreetMap tiles, member pins, route tails, stale-state labels, precision/accuracy rings, and place-radius preview.
- Native Android/iOS location bridge contracts for permission snapshots, companion mode, SOS fix, geofence hooks, and upload queues.
- Android native upload queue and iOS source implementation for encrypted bounded offline upload.
- Companion mode session creation/activation, manual `도착 확인`, check-in history UI, and ad-free safety summary.
- Privacy/안심 screen with sharing pause, ad preferences, data requests, battery mode, and native permission snapshot display.

Recent local verification:

```powershell
flutter analyze
flutter test
.\tools\build-flutter.ps1 -Target web
.\tools\build-flutter.ps1 -Target android-debug
```

Known open backend item:

- Supabase migrations through `008` are applied.
- `supabase/migrations/009_check_in_events.sql` is prepared but not yet applied to production because the current local session has no Supabase CLI, `psql`, service role key, or authenticated dashboard session.

## Product Principle

Do not compete by tracking more aggressively. Compete by making sharing feel safer:

- clear mutual consent
- visible viewer history
- per-circle precision controls
- battery-aware updates
- no precise-location ad targeting
- ads kept out of maps, SOS, onboarding, and permission dialogs
