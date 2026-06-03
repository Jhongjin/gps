# Permission And Consent Matrix

Date: 2026-05-30

| Area | Data | Purpose | Retention | User Control |
| --- | --- | --- | --- | --- |
| Foreground location | Current coordinate | Show my position and update active circle | Latest state only | Disable location permission |
| Background location | Coordinate samples | Place alerts and active companion sessions | Session queue, then minimized | Stop companion, pause sharing, revoke permission |
| Companion mode | Route tail, ETA, status | Time-limited safety sharing | Active session only by default | End session anytime |
| Place alerts | Geofence center/radius | Arrival/departure/late alerts | Until place rule deleted | Pause/delete place rule |
| SOS | Current fix and emergency metadata | Send urgent help request to trusted circle | Emergency event policy | End SOS flow |
| Ads | Ad ID or contextual ad request | Fund free service | Ad SDK policy | Personalized ads off |

## Non-Negotiable Rules

- Precise location is not used for ad targeting.
- Companion mode is explicit, time-limited, and visible.
- Sharing pause stops ordinary location sharing.
- Minor accounts default to non-personalized ads and guardian-safe consent.
- Privacy delete/export flows never show ads.

## Current App Surface

- `PrivacyScreen` displays the native foreground, background, precise, notification, and service-enabled permission snapshot when running on Android/iOS.
- Web preview keeps the same card but labels it as device-build verification.
