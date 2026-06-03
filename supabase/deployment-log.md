# Supabase Deployment Log

Date: 2026-06-03

Project:

- Name: gps
- Ref: `usetuwqbzkmywmtgwwdx`
- Dashboard: https://supabase.com/dashboard/project/usetuwqbzkmywmtgwwdx

## Applied

The following SQL migration files were applied through the Supabase SQL Editor:

- `supabase/migrations/001_initial_schema.sql`
- `supabase/migrations/002_backend_hardening.sql`
- `supabase/migrations/003_backend_rpcs.sql`
- `supabase/migrations/004_auth_profile_bootstrap.sql`
- `supabase/migrations/005_circle_creation_rpc.sql`
- `supabase/migrations/006_location_history_idempotency.sql`
- `supabase/migrations/007_location_upload_rls_hardening.sql`
- `supabase/migrations/008_circle_member_route_tail_rpc.sql`
- `supabase/migrations/009_check_in_events.sql`
- `supabase/migrations/010_check_in_session_ownership.sql`
- `supabase/migrations/011_place_alert_target_rpc.sql`

Prepared but not yet applied:

- `supabase/migrations/012_place_alert_management_rpcs.sql`

## SQL Editor Bundle

The following bundle was used to apply the post-initial migrations:

- `supabase/pending_production_migrations.sql`

Purpose:

- keep native `latest_locations` upserts working even if an early row predates `device_id`
- still require every new `device_id` to belong to the authenticated user
- provide a bounded, circle-authorized route-tail RPC that returns shared coordinates only

Post-apply verification:

- `route_tail_rpc_installed = true`
- `route_tail_rpc_granted = true`
- `latest_update_policy_hardened = true`

Additional read-only verification query:

- `supabase/verification_after_008.sql`

## Check-In Events Migration

The following SQL Editor migration was applied on 2026-06-03:

- `supabase/migrations/009_check_in_events.sql`
- `supabase/verification_after_009.sql`

Purpose:

- add coordinate-free manual check-in events
- add `perform_check_in` and `list_circle_check_ins`
- end the caller's companion session from the check-in RPC
- restrict direct `latest_locations` table reads to the owner row so circle views keep using shared-coordinate RPCs

Post-apply verification:

- `check_in_events_installed = true`
- `perform_check_in_installed = true`
- `list_circle_check_ins_installed = true`
- `latest_locations_raw_select_hardened = true`
- `broad_latest_locations_select_removed = true`

## Check-In Session Ownership Hardening

The following SQL Editor migration was applied on 2026-06-03:

- `supabase/migrations/010_check_in_session_ownership.sql`
- `supabase/verification_after_010.sql`
- `supabase/negative_tests_after_010.sql`

Purpose:

- reject check-ins that try to attach another member's companion session
- only end a companion session when it belongs to the caller subject
- require supplied companion sessions to still be pending or active and unexpired

Post-apply verification:

- `check_in_session_link_guard_installed = true`
- `check_in_session_subject_predicate_installed = true`
- `check_in_session_error_installed = true`
- `check_in_session_expiry_guard_installed = true`

Rollback-only negative test:

- `all_negative_tests_passed = true`
- 8 assertions passed for check-in visibility, raw latest-location RLS, outsider denial, and other-subject companion session rejection

## Place Alert Target Creation RPC

The following SQL Editor migration was applied on 2026-06-03:

- `supabase/migrations/011_place_alert_target_rpc.sql`
- `supabase/verification_after_011.sql`
- `supabase/negative_tests_after_011.sql`

Purpose:

- create place alerts and target rows atomically through one RPC
- block broad direct `place_alerts` inserts from clients
- require every target to be a same-circle member
- require non-self targets to be shareable by current privacy policy
- require minor targets to be self or guarded by the creator

Post-apply verification:

- `place_alert_create_rpc_installed = true`
- `place_alert_create_rpc_granted = true`
- `direct_place_alert_insert_blocked = true`
- `broad_place_alert_insert_removed = true`
- `minor_guardian_check_installed = true`
- `shareability_check_installed = true`

Rollback-only negative test:

- `all_place_alert_tests_passed = true`
- 8 assertions passed for direct insert denial, target validation, guardian checks, outsider denial, and valid member/minor creation

## Verification

Verification checked 25 expected objects:

- 15 tables
- 6 RPC/functions
- 3 key RLS policies
- 1 auth trigger

Result:

- Initial schema/RLS/RPC check: `installed_count = 22`
- `missing_count = 0`
- Auth bootstrap check: `function_installed = true`, `trigger_installed = true`
- Circle creation RPC check: `function_installed = true`, `authenticated_can_execute = true`, `circle_created_allowed = true`
- Location idempotency check: `idempotency_column_installed = true`, `idempotency_index_installed = true`
- Check-in events check: all `verification_after_009.sql` assertions returned `true`
- Check-in session ownership check: all `verification_after_010.sql` and rollback-only negative test assertions returned `true`
- Place alert target RPC check: all `verification_after_011.sql` and rollback-only negative test assertions returned `true`

Key verified objects:

- `profiles`
- `circles`
- `circle_members`
- `circle_invitations`
- `companion_sessions`
- `companion_session_members`
- `latest_locations`
- `location_history`
- `place_alert_events`
- `viewer_logs`
- `data_requests`
- `create_circle_invite`
- `accept_circle_invite`
- `get_circle_latest_locations`
- `record_viewer_log`
- `handle_new_auth_user`
- `create_circle_with_owner`
- `viewer_logs_no_client_insert`
- `latest_locations_owner_registered_device_insert`
- `circle_invitations_insert_circle_members`

## Next

- Create a real app signup from the Flutter auth gate and confirm profiles/ad preferences are auto-created.
- Create test users through Supabase Auth and confirm profiles/ad preferences are auto-created.
- Create a small seed circle through the app/RPC flow and confirm owner membership plus default sharing policy are created.
- Wire Flutter place alert creation UI to `create_place_alert_with_targets`.
