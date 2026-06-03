# Current Handoff

Date: 2026-05-31

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

- migrations through `008_circle_member_route_tail_rpc.sql`

Prepared but not applied:

- `supabase/migrations/009_check_in_events.sql`
- `supabase/pending_production_migrations.sql`
- `supabase/verification_after_009.sql`

Reason:

- current local session has no Supabase CLI, `psql`, service role key, DB password, or authenticated Supabase dashboard session.

## Next Backend Priority

1. Apply `009_check_in_events.sql`.
2. Run `verification_after_009.sql`.
3. Test unauthorized users cannot list another circle's check-ins.
4. Confirm direct `latest_locations` select no longer exposes another member's raw coordinates.
5. Decide place-alert target write RPC and companion-only route-tail RPC from `supabase/migration-backlog.md`.
