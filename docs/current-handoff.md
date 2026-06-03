# Current Handoff

Date: 2026-06-03

## Latest Preview

`http://127.0.0.1:4174/?v=1780229000000`

## Verified

- `flutter analyze`
- `flutter test`
- `tools/build-flutter.ps1 -Target web`
- `tools/build-flutter.ps1 -Target android-debug`

Android debug APK builds successfully. iOS source is implemented but not compiled in this Windows workspace.

## Implemented In Flutter

- Real map with OSM tiles, member markers, route tails, precision/accuracy rings, stale-state copy, and place-alert radius creation flow.
- Circle creation, invites, invite acceptance, empty states, place alert read state, and check-in status card.
- Companion mode session creation, consent, activation, native session config, manual `도착 확인`, and session ending.
- Active companion route tails are separated from ordinary map route tails in local code and SQL.
- Android encrypted bounded native upload queue and iOS source implementation for the same queue.
- Android saved place alerts register through Google Play Services Geofencing API and emit native enter/exit transition events.
- Place alert pause/resume/delete UI and creator-scoped RPC SQL are implemented locally.
- Place alert creation supports quiet-hours presets and circle rule cards display the saved summary.
- Saved place alert quiet-hours presets can be cycled from `CircleScreen` through local creator-scoped RPC SQL.
- Native place-alert enter/exit events update the in-app status copy without showing internal geofence ids.
- Android native place-alert transitions also show a privacy-safe local notification when notification permission is granted.
- iOS region enter/exit callbacks schedule matching privacy-safe local notifications in source; this Windows workspace cannot compile iOS.
- Authenticated Flutter clients record native place-alert transitions through local `015_place_alert_event_ingest_rpc.sql` RPC SQL.
- A `SafeAdSlot` placeholder is isolated to the history surface after the activity list; safety-critical screens remain ad-free.
- Native permission snapshot surfaced in Privacy/안심 screen on Android/iOS.
- History safety summary plus filters for `전체`, `확인`, `장소`, `동행`, and `데이터`.
- Widget smoke tests for shell, history filters, and privacy permission/battery controls.

## Backend State

Applied in production Supabase:

- migrations through `011_place_alert_target_rpc.sql`

Verified in production Supabase:

- `check_in_events_installed = true`
- `perform_check_in_installed = true`
- `list_circle_check_ins_installed = true`
- `latest_locations_raw_select_hardened = true`
- `broad_latest_locations_select_removed = true`
- `check_in_session_link_guard_installed = true`
- `check_in_session_subject_predicate_installed = true`
- `check_in_session_error_installed = true`
- `check_in_session_expiry_guard_installed = true`
- rollback-only RLS/RPC negative tests: 8 assertions passed
- `place_alert_create_rpc_installed = true`
- `place_alert_create_rpc_granted = true`
- `direct_place_alert_insert_blocked = true`
- `broad_place_alert_insert_removed = true`
- `minor_guardian_check_installed = true`
- `shareability_check_installed = true`
- rollback-only place alert negative tests: 8 assertions passed

Current local limitation:

- `supabase` CLI and `psql` are still not configured in this workspace; production DDL was applied through the Supabase SQL Editor browser session.
- `012_place_alert_management_rpcs.sql`, `013_active_companion_route_tail_rpc.sql`, `014_place_alert_quiet_hours_rpc.sql`, and `015_place_alert_event_ingest_rpc.sql` are prepared locally but not applied to production yet. The Supabase SQL Editor is visible in the in-app Browser, but automated editor input is blocked by the Browser virtual clipboard limitation.

## Next Backend Priority

1. Apply the pending production SQL bundle, then run verification/negative tests for `012` through `015`.
2. Add push notification delivery rules after event ingestion is production-applied.
3. Add real-device Android/iOS QA for geofence event delivery and dedupe.
