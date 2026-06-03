# 곁에 Supabase Backend

This folder contains the initial Supabase/Postgres backend scaffold for `곁에`.

The current desktop environment does not have the Supabase CLI configured. On a development machine:

```bash
supabase init
supabase link --project-ref <project-ref>
supabase db push
```

Current production project:

- Ref: `usetuwqbzkmywmtgwwdx`
- Applied through SQL Editor:
  - `migrations/007_location_upload_rls_hardening.sql`
  - `migrations/008_circle_member_route_tail_rpc.sql`
  - `migrations/009_check_in_events.sql`
  - `migrations/010_check_in_session_ownership.sql`
  - `migrations/011_place_alert_target_rpc.sql`
- Pending SQL Editor application:
  - `migrations/012_place_alert_management_rpcs.sql`
  - `migrations/013_active_companion_route_tail_rpc.sql`
  - `migrations/014_place_alert_quiet_hours_rpc.sql`
- Read-only verification queries:
  - `verification_after_008.sql`
  - `verification_after_009.sql`
  - `verification_after_010.sql`
  - `verification_after_011.sql`
  - `verification_after_012.sql`
  - `verification_after_013.sql`
  - `verification_after_014.sql`
- Rollback-only negative test:
  - `negative_tests_after_010.sql`
  - `negative_tests_after_011.sql`
  - `negative_tests_after_012.sql`
  - `negative_tests_after_013.sql`
  - `negative_tests_after_014.sql`
- Migration backlog: `migration-backlog.md`

## Role In The Architecture

Supabase owns:

- auth identity
- circles and invitations
- sharing policies
- latest location state
- companion session metadata
- place alert configuration
- place alert event dedupe
- coordinate-free safety check-in events
- viewer logs
- data export/delete requests

Realtime can be used for active circle channels, but location writes must still pass through policy checks. Under load, move high-volume location ingest to a dedicated service.

See `docs/backend-architecture.md` for the queue-level architecture and data flow.

## Privacy Rules

- Enable RLS on every exposed table.
- Do not store ad SDK identifiers in location tables.
- Do not store raw invitation tokens. Store only `invite_token_hash`.
- Store raw coordinates only where needed.
- Store shared/precision-adjusted coordinates separately from raw samples.
- Keep live route samples session-scoped by default.
- Default location history retention: 30 days.
