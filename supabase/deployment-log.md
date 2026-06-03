# Supabase Deployment Log

Date: 2026-05-30

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

## Prepared Next

The next SQL Editor bundle has been prepared but not yet applied in the current browser session:

- `supabase/migrations/009_check_in_events.sql`
- `supabase/pending_production_migrations.sql`
- `supabase/verification_after_009.sql`

Purpose:

- add coordinate-free manual check-in events
- add `perform_check_in` and `list_circle_check_ins`
- end the caller's companion session from the check-in RPC
- restrict direct `latest_locations` table reads to the owner row so circle views keep using shared-coordinate RPCs

Local apply status:

- `supabase` CLI: unavailable in this workspace
- `psql`: unavailable in this workspace
- available environment: publishable client configuration only, not sufficient for DDL
- in-app Supabase dashboard session: currently not authenticated

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
- Run RLS negative tests for unauthorized location reads and invite reuse.
