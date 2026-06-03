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
- `012_place_alert_management_rpcs.sql` and `013_active_companion_route_tail_rpc.sql` are prepared locally but not applied to production yet because the current in-app Browser session has no Supabase login cookie.

## Next Backend Priority

1. Apply the pending production SQL bundle, then run `verification_after_012.sql`, `negative_tests_after_012.sql`, `verification_after_013.sql`, and `negative_tests_after_013.sql`.
2. Add quiet-hours editing after notification delivery rules are implemented.
3. Add push/local notification delivery rules for place-alert transitions.
