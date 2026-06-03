# Native Implementation Plan

Date: 2026-05-30

## Queue Goal

Turn the Flutter bridge contract into real Swift/Kotlin code after `flutter create --platforms=ios,android .` generates native project folders.

## Order

1. Generate native folders and keep existing `lib/`, `pubspec.yaml`, and docs.
2. Add the Swift and Kotlin bridge classes from `native_stubs/`.
3. Wire `MethodChannel('app.gyeote/location')` and `EventChannel('app.gyeote/location_events')` in app startup.
4. Implement permission snapshot first, before any location collection.
5. Implement foreground-only live map updates.
6. Add companion-mode high cadence updates with explicit session expiry.
7. Add low-power place alerts through iOS region monitoring and Android Geofencing API.
8. Add native offline queue flush and backend upload only after consent/RLS paths pass.
9. Keep Dart from uploading production location samples; Dart can only request flush/status.

## iOS Tasks

- Add location background mode only when the production build actually supports background companion/place alerts.
- Add `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription`.
- Request `Always` only after a user starts companion mode or place alerts.
- Use `CLLocationManager` standard updates for active map and companion mode.
- Use significant-change, visits, or region monitoring for passive background behavior.
- Keep only the highest-priority monitored regions active and re-register after relaunch or large movement.
- Use `allowsBackgroundLocationUpdates = true` only during an active justified session.
- Emit `permission.changed` whenever authorization, precise location, or service availability changes.
- Persist `pausedUntil`, `expiresAt`, sharing mode, and consent version locally.
- Refuse ordinary collection when sharing mode is `hidden` or `sosOnly`.

## Android Tasks

- Add `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, and background location only when the feature needs it.
- Use Fused Location Provider for active updates.
- Use a `location` foreground service for companion mode and long-running active sharing.
- Use Geofencing API for place alerts instead of constant GPS polling.
- Handle Android 10+ background permission review and Android 13+ notification permission.
- Detect battery saver and OEM restriction paths and expose them to Flutter.
- Queue samples locally while offline and flush with `flushPendingLocations`.
- Use `deviceId + sequence + recordedAt` idempotency for native uploads.
- Stop service when session expires, the user checks in, or sharing is paused.

## Store Review Notes

- Background location is core functionality only for companion mode and place alerts.
- SOS, permission, delete/export, and safety confirmation screens must not show ads.
- App review video should show: user starts companion mode, persistent Android notification/iOS indicator appears, user stops sharing, background updates stop.

## References

- Apple Core Location authorization and background behavior: https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services
- Android background location checklist: https://developer.android.com/develop/sensors-and-location/location/background
- Google Play background location declaration: https://support.google.com/googleplay/android-developer/answer/9799150
