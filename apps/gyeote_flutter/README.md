# 곁에 Flutter App

This is the production app scaffold for `곁에`.

The project now includes Flutter `web`, `android`, and `ios` platform folders. This workspace also has local toolchains installed at the workspace root:

- Flutter SDK: `E:\codex\toolchains\flutter`
- Android SDK: `E:\codex\android-sdk`
- Pub cache: `E:\codex\pub-cache`
- JDK: Microsoft OpenJDK 21

Use the helper scripts from the repository root so PATH, `PUB_CACHE`, Android SDK, JDK, and `.env.local` dart defines are applied consistently:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run-flutter.ps1 -d chrome
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-flutter.ps1 -Target web
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-flutter.ps1 -Target android-debug
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\android-qa.ps1 -Install -Launch -Logcat
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\serve-prototype.ps1 -Root .\apps\gyeote_flutter\build\web -Port 4174
```

If running on another development machine, install Flutter and generate/refresh platform folders only when needed:

```bash
cd apps/gyeote_flutter
flutter create --platforms=web,ios,android .
flutter pub get
flutter run
```

If `flutter create` asks about overwriting files, keep the existing `lib/`, `pubspec.yaml`, and `README.md` content.

## Direction

- Flutter owns cross-platform UI.
- Swift/Kotlin own background location, foreground service, geofencing, and platform permission details.
- Flutter talks to native code through `MethodChannel('app.gyeote/location')` and `EventChannel('app.gyeote/location_events')`.
- Flutter talks to the backend through repository contracts in `lib/src/core/backend/backend_contract.dart`.
- Android native upload queues live location samples in an encrypted bounded file queue and flushes them to Supabase through PostgREST.
- Backend mapping is documented in `docs/backend-contract.md`.
- Native implementation order is documented in `docs/native-implementation-plan.md`.
- Map provider selection is documented in `docs/map-sdk-plan.md`.
- Naver Maps SDK should be integrated in the native map layer or through a vetted Flutter plugin after a real-device spike.

## Current Verified Features

- Map: OSM tile map, member markers, route tails, stale state, precision rings, and place radius preview.
- Circle: real Supabase circle creation, invite generation, invite acceptance, member empty state, place alert read state, and check-in state.
- Companion: session creation, mutual-consent record, session activation, native companion location config, manual check-in, and session ending.
- Native upload: Android encrypted bounded upload queue; iOS source implementation for the same queue.
- Privacy: sharing pause, ad preferences, data requests, battery mode control, and `PermissionSnapshot` display on Android/iOS.
- History: check-in events, safety summary, and activity filters.

Latest local verification:

```powershell
flutter analyze
flutter test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-flutter.ps1 -Target web
powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\build-flutter.ps1 -Target android-debug
```

Current backend caveat: `supabase/migrations/009_check_in_events.sql` is prepared and bundled, but production DB application is still pending.

## First Production Spike

1. Implement the native bridge methods described in `docs/native-location-bridge.md`.
2. Verify foreground/background location on real Android and iOS devices.
3. Confirm background updates stop or return to normal cadence when companion mode ends.
4. Add ad SDK only after verifying it never receives precise location, route, SOS, or permission state.
5. Replace public OpenStreetMap tiles before production if traffic exceeds the OSM public tile usage policy.
