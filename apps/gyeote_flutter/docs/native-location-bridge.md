# Native Location Bridge Contract

Date: 2026-05-30

## Channels

- MethodChannel: `app.gyeote/location`
- EventChannel: `app.gyeote/location_events`

Flutter owns UI, consent screens, and visible state. Swift/Kotlin own OS permissions, background location, foreground service, geofences, local queueing, and production location upload.

MVP upload decision: native code is the single writer for location samples. Flutter can request `flushPendingLocations` and read live events, but it must not also upload the same sample. Register the app install through `DeviceRepository.registerDevice`, persist the returned `deviceId`, then use `deviceId + sequence + recordedAt` as the idempotency key; Supabase stores it on `location_history` to dedupe retries.

## Required Method Calls

- `getPermissionSnapshot`
- `requestWhenInUse`
- `requestAlways`
- `startLocationSession`
- `stopLocationSession`
- `setSharingPolicy`
- `getLastKnownLocation`
- `registerGeofences`
- `configureUpload`
- `clearUploadConfig`
- `flushPendingLocations`
- `requestSosFix`

## Required Events

- `location.updated`
- `permission.changed`
- `service.statusChanged`
- `geofence.entered`
- `geofence.exited`
- `location.error`

Every event payload must include:

- `schemaVersion`
- `sequence`
- `idempotencyKey` for uploadable location samples
- `recordedAt`
- `source`
- `permissionSnapshot`
- `consentVersion`

## Error Codes

Use fixed error codes instead of free-form strings:

- `permission_denied`
- `background_denied`
- `precise_disabled`
- `provider_disabled`
- `battery_restricted`
- `service_killed`
- `policy_paused`
- `consent_missing`
- `invalid_payload`
- `upload_network_failed`
- `upload_auth_failed`
- `upload_failed`

## Privacy Rules

- Native must refuse collection when consent is missing.
- Native must refuse ordinary collection when sharing is paused.
- `sosOnly` permits SOS fix only, not passive collection.
- Native must persist `consentVersion`, `pausedUntil`, `expiresAt`, and sharing mode locally and re-check them before every collection/upload.
- When a companion session is revoked or expires, native must stop collection and discard pending session-scoped route samples.
- If precise location is disabled, native must downgrade to shared/approximate coordinates.
- Raw latitude/longitude must never be passed to ads or analytics.
- Logs must not include coordinates, invite tokens, phone numbers, or user identifiers.

## Data Separation

`LocationSample` intentionally has:

- `rawCoordinate`: device-only or protected pipeline
- `sharedCoordinate`: precision-adjusted coordinate safe for circle display

Approximate sharing, history deletion, and ad isolation depend on this separation.

## Real Device QA

- foreground permission denied
- background permission denied
- precise location disabled
- notifications denied
- app force-closed
- battery saver / OEM restriction
- network offline
- companion session expired
- companion session manually stopped
- SOS fix requested while normal sharing is hidden

## Platform Notes

## Implementation Status

- Android bridge and foreground service slices are implemented in:
  - `android/app/src/main/kotlin/app/gyeote/gyeote/MainActivity.kt`
  - `android/app/src/main/kotlin/app/gyeote/gyeote/GyeoteLocationCore.kt`
  - `android/app/src/main/kotlin/app/gyeote/gyeote/LocationForegroundService.kt`
  - `android/app/src/main/kotlin/app/gyeote/gyeote/GeofenceBroadcastReceiver.kt`
  - Covers permission snapshot, foreground/background permission requests, notification-backed foreground location service, last known location, live location events, SOS single fix, sharing policy checks, and Google Play Services Geofencing API registration for saved place alerts.
  - Flutter consumes `geofence.entered` / `geofence.exited` events and surfaces a user-facing place-alert status without exposing internal geofence ids.
  - Android shows a privacy-safe local notification for saved-place enter/exit transitions when notification permission is granted.
  - Native upload settings, Android Keystore encrypted bounded queue, and PostgREST flush are implemented in `GyeoteLocationUploadQueue.kt`.
  - Upload failures preserve pending samples, emit queue status to Flutter, and retry with bounded exponential backoff. `configureUpload` and manual `flushPendingLocations` force a fresh attempt after token refresh or user action.
  - Native token refresh remains before production-scale background upload.
- iOS first bridge slice is implemented in `ios/Runner/AppDelegate.swift`.
  - Covers channel registration, permission requests, live location events, SOS single fix, sharing policy checks, and region monitoring hooks.
  - Region enter/exit events emit Flutter bridge events and schedule privacy-safe local notifications when notification permission is granted.
  - Upload configuration, file-protected bounded queueing, PostgREST latest/history flush, retry backoff, and auth failure surfacing are source-implemented.
  - iOS source is ready for Xcode/device validation; this Windows workspace cannot compile iOS.

### iOS

- Request `When In Use` first; request `Always` only after the user starts a feature that clearly needs background location.
- Include `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription`.
- Handle `Allow Once`, `When In Use`, `Always`, denied, and Precise Off states in `PermissionSnapshot`.
- Use standard updates only for active viewing, companion mode, or SOS.
- Use significant-change, visits, and region monitoring for lower-power background behavior.
- Set `allowsBackgroundLocationUpdates` only while an active feature justifies it.
- Stop background updates when sharing is paused, companion mode ends, or the session expires.
- Respect the region monitoring limit by prioritizing the nearest and most important places, then re-register after movement or app relaunch.

### Android

- Declare fine/coarse location, notification, foreground service, and foreground service location permissions in the generated Android project.
- Request `ACCESS_BACKGROUND_LOCATION` only for core features that truly need it, such as place alerts or active companion sessions.
- Start the location foreground service from a visible user action when possible.
- Use Fused Location Provider for updates and Geofencing API for place alerts.
- Detect battery saver, Doze, and OEM background restrictions and surface them as `battery_restricted` or `service_killed`.
- Keep the persistent notification clear: who is sharing, why, and how to stop.
- Store a bounded encrypted/offline queue and retry with idempotency after network recovery.
