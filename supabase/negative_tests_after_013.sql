-- Rollback-only RPC negative tests for active companion route tails.
-- The SELECT result is shown before ROLLBACK, and all fixture rows are discarded.

begin;

create temp table gyeote_companion_route_results (
  name text primary key,
  passed boolean not null,
  detail text
) on commit drop;

grant all on table gyeote_companion_route_results to authenticated;

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  (
    '13131313-1313-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'gyeote-companion-subject@example.invalid',
    '{"display_name":"Companion Subject"}'::jsonb
  ),
  (
    '13131313-1313-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'gyeote-companion-viewer@example.invalid',
    '{"display_name":"Companion Viewer"}'::jsonb
  ),
  (
    '13131313-1313-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'gyeote-companion-outsider@example.invalid',
    '{"display_name":"Companion Outsider"}'::jsonb
  );

insert into public.circles (id, name, created_by)
values ('13131313-1313-4000-8000-000000000101', 'Companion Route Circle', '13131313-1313-4000-8000-000000000001');

insert into public.circle_members (circle_id, profile_id, role, can_view_location)
values
  ('13131313-1313-4000-8000-000000000101', '13131313-1313-4000-8000-000000000001', 'owner', true),
  ('13131313-1313-4000-8000-000000000101', '13131313-1313-4000-8000-000000000002', 'member', true);

insert into public.companion_sessions (
  id,
  circle_id,
  subject_profile_id,
  started_by,
  status,
  started_at,
  expires_at
)
values
  (
    '13131313-1313-4000-8000-000000000201',
    '13131313-1313-4000-8000-000000000101',
    '13131313-1313-4000-8000-000000000001',
    '13131313-1313-4000-8000-000000000001',
    'active',
    now() - interval '20 minutes',
    now() + interval '40 minutes'
  ),
  (
    '13131313-1313-4000-8000-000000000202',
    '13131313-1313-4000-8000-000000000101',
    '13131313-1313-4000-8000-000000000001',
    '13131313-1313-4000-8000-000000000001',
    'ended',
    now() - interval '20 minutes',
    now() + interval '40 minutes'
  ),
  (
    '13131313-1313-4000-8000-000000000203',
    '13131313-1313-4000-8000-000000000101',
    '13131313-1313-4000-8000-000000000001',
    '13131313-1313-4000-8000-000000000001',
    'active',
    now() - interval '20 minutes',
    now() - interval '1 minute'
  );

insert into public.companion_session_members (session_id, profile_id, consented_at, can_view)
values
  ('13131313-1313-4000-8000-000000000201', '13131313-1313-4000-8000-000000000001', now() - interval '19 minutes', true),
  ('13131313-1313-4000-8000-000000000201', '13131313-1313-4000-8000-000000000002', now() - interval '19 minutes', true),
  ('13131313-1313-4000-8000-000000000202', '13131313-1313-4000-8000-000000000001', now() - interval '19 minutes', true),
  ('13131313-1313-4000-8000-000000000202', '13131313-1313-4000-8000-000000000002', now() - interval '19 minutes', true),
  ('13131313-1313-4000-8000-000000000203', '13131313-1313-4000-8000-000000000001', now() - interval '19 minutes', true),
  ('13131313-1313-4000-8000-000000000203', '13131313-1313-4000-8000-000000000002', now() - interval '19 minutes', true);

insert into public.location_history (
  profile_id,
  companion_session_id,
  source,
  raw_lat,
  raw_lng,
  shared_lat,
  shared_lng,
  accuracy_m,
  sharing_precision,
  recorded_at
)
values
  (
    '13131313-1313-4000-8000-000000000001',
    null,
    'network',
    37.498,
    127.034,
    37.498,
    127.034,
    20,
    'balanced',
    now() - interval '25 minutes'
  ),
  (
    '13131313-1313-4000-8000-000000000001',
    '13131313-1313-4000-8000-000000000201',
    'companion',
    37.501,
    127.039,
    37.501,
    127.039,
    12,
    'precise',
    now() - interval '12 minutes'
  ),
  (
    '13131313-1313-4000-8000-000000000001',
    '13131313-1313-4000-8000-000000000201',
    'companion',
    37.502,
    127.040,
    37.502,
    127.040,
    12,
    'precise',
    now() - interval '5 minutes'
  ),
  (
    '13131313-1313-4000-8000-000000000001',
    '13131313-1313-4000-8000-000000000202',
    'companion',
    37.503,
    127.041,
    37.503,
    127.041,
    12,
    'precise',
    now() - interval '4 minutes'
  ),
  (
    '13131313-1313-4000-8000-000000000001',
    '13131313-1313-4000-8000-000000000203',
    'companion',
    37.504,
    127.042,
    37.504,
    127.042,
    12,
    'precise',
    now() - interval '3 minutes'
  );

set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '13131313-1313-4000-8000-000000000002';

insert into gyeote_companion_route_results (name, passed, detail)
select
  'participant_can_read_active_session_tail',
  count(*) = 2,
  count(*)::text
from public.get_active_companion_route_tail(
  '13131313-1313-4000-8000-000000000201',
  '13131313-1313-4000-8000-000000000001',
  20,
  now() - interval '45 minutes'
);

insert into gyeote_companion_route_results (name, passed, detail)
select
  'ordinary_history_is_excluded',
  count(*) = 0,
  count(*)::text
from public.get_active_companion_route_tail(
  '13131313-1313-4000-8000-000000000201',
  '13131313-1313-4000-8000-000000000001',
  20,
  now() - interval '45 minutes'
)
where shared_lat = 37.498;

insert into gyeote_companion_route_results (name, passed, detail)
select
  'ended_session_returns_no_tail',
  count(*) = 0,
  count(*)::text
from public.get_active_companion_route_tail(
  '13131313-1313-4000-8000-000000000202',
  '13131313-1313-4000-8000-000000000001',
  20,
  now() - interval '45 minutes'
);

insert into gyeote_companion_route_results (name, passed, detail)
select
  'expired_session_returns_no_tail',
  count(*) = 0,
  count(*)::text
from public.get_active_companion_route_tail(
  '13131313-1313-4000-8000-000000000203',
  '13131313-1313-4000-8000-000000000001',
  20,
  now() - interval '45 minutes'
);

set local "request.jwt.claim.sub" = '13131313-1313-4000-8000-000000000003';

insert into gyeote_companion_route_results (name, passed, detail)
select
  'outsider_gets_no_tail',
  count(*) = 0,
  count(*)::text
from public.get_active_companion_route_tail(
  '13131313-1313-4000-8000-000000000201',
  '13131313-1313-4000-8000-000000000001',
  20,
  now() - interval '45 minutes'
);

reset role;

select
  bool_and(passed) as all_active_companion_route_tests_passed,
  jsonb_object_agg(name, passed order by name) as assertions,
  jsonb_object_agg(name, detail order by name) filter (where not passed) as failures
from gyeote_companion_route_results;

rollback;
