# Current Handoff

Date: 2026-06-03

## Latest Preview

`http://127.0.0.1:4174/?v=1780220654147`

## Verified

- `flutter analyze`
- `flutter test`
- `tools/build-flutter.ps1 -Target web`
- `tools/build-flutter.ps1 -Target android-debug`

Android debug APK builds successfully. iOS source is implemented but not compiled in this Windows workspace.

## Implemented In Flutter

- Real map with OSM tiles, member markers, route tails, precision/accuracy rings, stale-state copy, and place-radius preview.
- Circle creation, invites, invite acceptance, empty states, place alert read state, and check-in status card.
- Companion mode session creation, consent, activation, native session config, manual `도착 확인`, and session ending.
- Android encrypted bounded native upload queue and iOS source implementation for the same queue.
- Native permission snapshot surfaced in Privacy/안심 screen on Android/iOS.
- History safety summary plus filters for `전체`, `확인`, `장소`, `동행`, and `데이터`.
- Widget smoke tests for shell, history filters, and privacy permission/battery controls.

## Backend State

Applied in production Supabase:

- migrations through `009_check_in_events.sql`

Verified in production Supabase:

- `check_in_events_installed = true`
- `perform_check_in_installed = true`
- `list_circle_check_ins_installed = true`
- `latest_locations_raw_select_hardened = true`
- `broad_latest_locations_select_removed = true`

Current local limitation:

- `supabase` CLI and `psql` are still not configured in this workspace; production DDL was applied through the Supabase SQL Editor browser session.

## Next Backend Priority

1. Add or run authenticated negative tests for check-in list access and direct `latest_locations` reads.
2. Confirm `perform_check_in` cannot end a companion session for another subject.
3. Decide place-alert target write RPC and companion-only route-tail RPC from `supabase/migration-backlog.md`.
