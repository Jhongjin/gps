# Supabase Migration Backlog

Date: 2026-06-03

## Applied

Applied through the Supabase SQL Editor on 2026-06-03:

- `migrations/009_check_in_events.sql`
- `migrations/010_check_in_session_ownership.sql`
- `migrations/011_place_alert_target_rpc.sql`
- `verification_after_009.sql`
- `verification_after_010.sql`
- `negative_tests_after_010.sql`
- `verification_after_011.sql`
- `negative_tests_after_011.sql`

Purpose:

- create coordinate-free manual check-in events
- add `perform_check_in` and `list_circle_check_ins`
- end the caller's companion session from the check-in RPC
- remove broad direct reads from `latest_locations`

Expected verification:

- `check_in_events_installed = true`
- `perform_check_in_installed = true`
- `list_circle_check_ins_installed = true`
- `latest_locations_raw_select_hardened = true`
- `broad_latest_locations_select_removed = true`

Result:

- all expected verification fields returned `true`
- check-in session ownership hardening returned all `verification_after_010.sql` fields as `true`
- rollback-only RLS/RPC negative test returned `all_negative_tests_passed = true` across 8 assertions
- place alert target RPC returned all `verification_after_011.sql` fields as `true`
- rollback-only place alert negative test returned `all_place_alert_tests_passed = true` across 8 assertions

## Pending Production Apply: Place Alert Management And Companion Route RPCs

Current state:

- `place_alerts` direct client inserts are blocked.
- `place_alert_targets` remains read-only from the client.
- `create_place_alert_with_targets` atomically validates and writes alert targets.
- Flutter can create alerts, pause/resume them, delete them, and re-sync native geofences.

Prepared files:

- `migrations/012_place_alert_management_rpcs.sql`
- `verification_after_012.sql`
- `negative_tests_after_012.sql`
- `migrations/013_active_companion_route_tail_rpc.sql`
- `verification_after_013.sql`
- `negative_tests_after_013.sql`

Production apply is still pending because the current in-app Browser session is not logged into Supabase Studio.

## Route Tail Semantics

Current state:

- `get_circle_member_route_tail` returns bounded shared-coordinate history for authorized viewers.
- `get_active_companion_route_tail` is prepared locally for active, unexpired, consented companion sessions.
- App-side check-in clears the live route tail after `도착 확인`.
- Backend SQL now distinguishes ordinary recent route tail from active companion route tail after production apply.

Decision:

1. Keep `get_circle_member_route_tail` as the low-frequency map tail.
2. Use `get_active_companion_route_tail` for high-frequency companion paths.
3. After `perform_check_in`, companion-specific route views stop because the session is `ended`.

## Completed Negative Tests

- unauthorized user cannot list another circle's check-ins
- direct `latest_locations` select no longer exposes another member's raw coordinates
- `perform_check_in` cannot end a companion session for another subject
- place alert target write RPC rejects a target outside the circle
- place alert target write RPC rejects or gates minor targets without guardian-safe consent

## Negative Tests To Add

- native geofence registration rejects alerts outside the signed-in user's visible circles
- native device QA confirms paused/deleted alerts remove stale OS geofences
