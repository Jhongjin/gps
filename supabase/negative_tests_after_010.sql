-- Rollback-only RLS and RPC negative tests for the check-in flow.
-- The SELECT result is shown before ROLLBACK, and all fixture rows are discarded.

begin;

create temp table gyeote_negative_results (
  name text primary key,
  passed boolean not null,
  detail text
) on commit drop;

grant all on table gyeote_negative_results to authenticated;

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  (
    '11111111-0909-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'gyeote-negative-a@example.invalid',
    '{"display_name":"Negative A"}'::jsonb
  ),
  (
    '11111111-0909-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'gyeote-negative-b@example.invalid',
    '{"display_name":"Negative B"}'::jsonb
  ),
  (
    '11111111-0909-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'gyeote-negative-c@example.invalid',
    '{"display_name":"Negative C"}'::jsonb
  );

insert into public.circles (id, name, created_by)
values
  ('11111111-0909-4000-8000-000000000101', 'Negative Circle A', '11111111-0909-4000-8000-000000000001'),
  ('11111111-0909-4000-8000-000000000102', 'Negative Circle C', '11111111-0909-4000-8000-000000000003');

insert into public.circle_members (circle_id, profile_id, role, can_view_location)
values
  ('11111111-0909-4000-8000-000000000101', '11111111-0909-4000-8000-000000000001', 'owner', true),
  ('11111111-0909-4000-8000-000000000101', '11111111-0909-4000-8000-000000000002', 'member', true),
  ('11111111-0909-4000-8000-000000000102', '11111111-0909-4000-8000-000000000003', 'owner', true);

insert into public.sharing_policies (circle_id, profile_id, precision, enabled)
values
  ('11111111-0909-4000-8000-000000000101', '11111111-0909-4000-8000-000000000001', 'balanced', true),
  ('11111111-0909-4000-8000-000000000101', '11111111-0909-4000-8000-000000000002', 'balanced', true),
  ('11111111-0909-4000-8000-000000000102', '11111111-0909-4000-8000-000000000003', 'balanced', true);

insert into public.devices (id, profile_id, platform)
values
  ('11111111-0909-4000-8000-000000000201', '11111111-0909-4000-8000-000000000002', 'android');

insert into public.latest_locations (
  profile_id,
  device_id,
  source,
  raw_lat,
  raw_lng,
  shared_lat,
  shared_lng,
  accuracy_m,
  sharing_precision,
  recorded_at
)
values (
  '11111111-0909-4000-8000-000000000002',
  '11111111-0909-4000-8000-000000000201',
  'gps',
  37.501,
  127.039,
  37.501,
  127.039,
  12,
  'balanced',
  now()
);

insert into public.companion_sessions (
  id,
  circle_id,
  subject_profile_id,
  started_by,
  status,
  precision,
  started_at,
  expires_at
)
values
  (
    '11111111-0909-4000-8000-000000000301',
    '11111111-0909-4000-8000-000000000101',
    '11111111-0909-4000-8000-000000000002',
    '11111111-0909-4000-8000-000000000001',
    'active',
    'balanced',
    now(),
    now() + interval '30 minutes'
  ),
  (
    '11111111-0909-4000-8000-000000000302',
    '11111111-0909-4000-8000-000000000101',
    '11111111-0909-4000-8000-000000000002',
    '11111111-0909-4000-8000-000000000001',
    'active',
    'balanced',
    now(),
    now() + interval '30 minutes'
  );

set local role authenticated;
set local row_security = on;

set local "request.jwt.claim.sub" = '11111111-0909-4000-8000-000000000002';

insert into gyeote_negative_results (name, passed, detail)
select
  'subject_can_create_check_in_and_end_own_session',
  count(*) = 1,
  count(*)::text
from public.perform_check_in(
  '11111111-0909-4000-8000-000000000101',
  '11111111-0909-4000-8000-000000000301',
  'safe_arrived',
  'negative-subject-owned-session'
);

insert into gyeote_negative_results (name, passed, detail)
select
  'subject_direct_latest_location_self_allowed',
  count(*) = 1,
  count(*)::text
from public.latest_locations
where profile_id = '11111111-0909-4000-8000-000000000002';

set local "request.jwt.claim.sub" = '11111111-0909-4000-8000-000000000001';

insert into gyeote_negative_results (name, passed, detail)
select
  'circle_member_can_list_visible_check_in',
  count(*) = 1,
  count(*)::text
from public.list_circle_check_ins('11111111-0909-4000-8000-000000000101', 20)
where subject_profile_id = '11111111-0909-4000-8000-000000000002';

insert into gyeote_negative_results (name, passed, detail)
select
  'circle_member_direct_latest_location_raw_blocked',
  count(*) = 0,
  count(*)::text
from public.latest_locations
where profile_id = '11111111-0909-4000-8000-000000000002';

do $$
begin
  perform *
  from public.perform_check_in(
    '11111111-0909-4000-8000-000000000101',
    '11111111-0909-4000-8000-000000000302',
    'safe_arrived',
    'negative-other-subject-session'
  );

  insert into gyeote_negative_results (name, passed, detail)
  values ('other_subject_companion_session_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_negative_results (name, passed, detail)
    values (
      'other_subject_companion_session_rejected',
      sqlerrm = 'companion_session_subject_required',
      sqlerrm
    );
end $$;

insert into gyeote_negative_results (name, passed, detail)
select
  'other_subject_companion_session_stays_active',
  status = 'active',
  status::text
from public.companion_sessions
where id = '11111111-0909-4000-8000-000000000302';

set local "request.jwt.claim.sub" = '11111111-0909-4000-8000-000000000003';

insert into gyeote_negative_results (name, passed, detail)
select
  'outsider_cannot_list_circle_check_ins',
  count(*) = 0,
  count(*)::text
from public.list_circle_check_ins('11111111-0909-4000-8000-000000000101', 20);

insert into gyeote_negative_results (name, passed, detail)
select
  'outsider_direct_latest_location_raw_blocked',
  count(*) = 0,
  count(*)::text
from public.latest_locations
where profile_id = '11111111-0909-4000-8000-000000000002';

reset role;

select
  bool_and(passed) as all_negative_tests_passed,
  jsonb_object_agg(name, passed order by name) as assertions,
  jsonb_object_agg(name, detail order by name) filter (where not passed) as failures
from gyeote_negative_results;

rollback;
