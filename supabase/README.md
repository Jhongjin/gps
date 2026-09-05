# 곁에 Supabase Backend

This folder contains the initial Supabase/Postgres backend scaffold for `곁에`.

The Supabase CLI is available now, so applying the pending migrations no longer
means pasting SQL into the dashboard. Use the script, which inspects before it
changes anything:

```powershell
.	oolspply-migrations.ps1          # compare local and remote, change nothing
.	oolspply-migrations.ps1 -Apply   # push after you have read the comparison
```

**Read the comparison before pushing.** Two hazards are stacked here.

`007` through `011` were applied by hand in the SQL Editor, which leaves no row
in the remote `supabase_migrations.schema_migrations`. The CLI only reads that
table, so it treats those five as unapplied and will try to run them again —
along with `001`, which creates tables. Mark them first:

```bash
supabase migration repair --status applied 007   # ... through 011
```

The file names are also non-standard. The CLI generates
`20260905150519_name.sql` and compares versions in that shape; this repo uses
`012_place_alert_management_rpcs.sql`. Renaming them after some are already
applied would be worse than living with it, so the comparison step is how you
confirm the CLI read them the way you expect.

Current production project:

- Ref: `usetuwqbzkmywmtgwwdx`
- Applied through SQL Editor:
  - `migrations/007_location_upload_rls_hardening.sql`
  - `migrations/008_circle_member_route_tail_rpc.sql`
  - `migrations/009_check_in_events.sql`
  - `migrations/010_check_in_session_ownership.sql`
  - `migrations/011_place_alert_target_rpc.sql`
- Pending application:
  - `migrations/012_place_alert_management_rpcs.sql`
  - `migrations/013_active_companion_route_tail_rpc.sql`
  - `migrations/014_place_alert_quiet_hours_rpc.sql`
  - `migrations/015_place_alert_event_ingest_rpc.sql`
  - `migrations/016_quick_reply_statuses.sql`
  - `migrations/017_meetups.sql`
- Read-only verification queries:
  - `verification_after_008.sql`
  - `verification_after_009.sql`
  - `verification_after_010.sql`
  - `verification_after_011.sql`
  - `verification_after_012.sql`
  - `verification_after_013.sql`
  - `verification_after_014.sql`
  - `verification_after_015.sql`
  - `verification_after_016.sql`
  - `verification_after_017.sql`
- Rollback-only negative test:
  - `negative_tests_after_010.sql`
  - `negative_tests_after_011.sql`
  - `negative_tests_after_012.sql`
  - `negative_tests_after_013.sql`
  - `negative_tests_after_014.sql`
  - `negative_tests_after_015.sql`
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
