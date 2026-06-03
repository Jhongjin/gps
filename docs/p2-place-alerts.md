# P2 Place Alerts Plan

Date: 2026-06-03

## Goal

Make place alerts useful without making them feel like covert monitoring.

## Required Controls

- place radius
- target members
- arrival alert
- departure alert
- late arrival alert
- long stay alert
- quiet hours
- temporary pause

## UX Rules

- Show the radius on the map before saving.
- Explain who receives the alert.
- Explain which member the rule applies to.
- Use neutral copy: `늦음 확인`, not `이탈 감지`.
- Do not put ads near save/delete/radius controls.

## QA Gates

- Place alert creation requires consent for the tracked member or guardian-safe child account handling.
- Home, school, hospital, and workplace are sensitive; avoid exposing exact addresses in unnecessary notifications.
- Alerts must be easy to pause.

## Current Implementation

- `PlaceAlertRepository.listPlaceAlerts` reads circle-scoped rules from Supabase under RLS.
- `PlaceAlertRepository.createPlaceAlert` writes through `create_place_alert_with_targets`.
- `CircleScreen` shows real alert rules when present and a backend-aware empty state when the circle has no rules.
- `MapScreen` includes radius preview for 100m, 300m, and 500m place alerts.
- `MapScreen` can save a place alert when a real Supabase circle and live server member ids are available.
- Direct client inserts into `place_alerts` are blocked; targets are written only by the RPC after same-circle, shareability, and guardian checks.
- After save, Android/iOS builds ask the native bridge to register up to 20 enabled arrival/departure geofences.
- Android now registers those rules through Google Play Services Geofencing API and emits `geofence.entered` / `geofence.exited` when the OS delivers transitions.
- Creator-scoped pause/resume and delete RPCs are prepared in `012_place_alert_management_rpcs.sql`.
- `CircleScreen` has pause/resume/delete actions and re-syncs native geofences after each change.
- `MapScreen` can save quiet-hours presets during creation and `CircleScreen` displays the saved quiet-hours summary.

## Next Implementation

- Apply `012_place_alert_management_rpcs.sql` to production Supabase and run the matching verification/negative tests.
- Add quiet-hours editing after notification delivery rules are implemented.
