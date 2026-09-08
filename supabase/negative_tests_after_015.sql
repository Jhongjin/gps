-- Rollback-only RPC negative tests for place alert event ingest.
-- The SELECT result is shown before ROLLBACK, and all fixture rows are discarded.

begin;

create temp table gyeote_place_alert_event_results (
  name text primary key,
  passed boolean not null,
  detail text
) on commit drop;

grant all on table gyeote_place_alert_event_results to authenticated;

-- 서클 밖 사람은 RLS 때문에 알림 행을 못 본다. 그 역할로 id 를 조회하면 null
-- 이 나오고 RPC 는 place_alert_not_found 를 낸다 — RLS 가 한 일이지 검사하려는
-- 대상 검사(place_alert_target_required)가 한 일이 아니다. 만든 사람이 볼 수
-- 있을 때 id 를 담아 둔다.
create temp table gyeote_place_alert_event_fixture (
  alert_id uuid not null
) on commit drop;

grant all on table gyeote_place_alert_event_fixture to authenticated;

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  (
    '15151515-1515-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'gyeote-place-event-owner@example.invalid',
    '{"display_name":"Event Owner"}'::jsonb
  ),
  (
    '15151515-1515-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'gyeote-place-event-target@example.invalid',
    '{"display_name":"Event Target"}'::jsonb
  ),
  (
    '15151515-1515-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'gyeote-place-event-outsider@example.invalid',
    '{"display_name":"Event Outsider"}'::jsonb
  );

insert into public.circles (id, name, created_by)
values ('15151515-1515-4000-8000-000000000101', 'Event Circle', '15151515-1515-4000-8000-000000000001');

insert into public.circle_members (circle_id, profile_id, role, can_view_location)
values
  ('15151515-1515-4000-8000-000000000101', '15151515-1515-4000-8000-000000000001', 'owner', true),
  ('15151515-1515-4000-8000-000000000101', '15151515-1515-4000-8000-000000000002', 'member', true);

insert into public.sharing_policies (circle_id, profile_id, precision, enabled)
values
  ('15151515-1515-4000-8000-000000000101', '15151515-1515-4000-8000-000000000001', 'balanced', true),
  ('15151515-1515-4000-8000-000000000101', '15151515-1515-4000-8000-000000000002', 'balanced', true);

set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '15151515-1515-4000-8000-000000000001';

insert into gyeote_place_alert_event_results (name, passed, detail)
select
  'owner_can_create_alert_for_target',
  count(*) = 1,
  count(*)::text
from public.create_place_alert_with_targets(
  '15151515-1515-4000-8000-000000000101',
  'Event Place',
  37.501,
  127.039,
  300,
  array['15151515-1515-4000-8000-000000000002']::uuid[],
  true,
  false,
  false,
  false,
  '{}'::jsonb
);

insert into gyeote_place_alert_event_fixture (alert_id)
select id from public.place_alerts where name = 'Event Place' limit 1;

set local "request.jwt.claim.sub" = '15151515-1515-4000-8000-000000000002';

insert into gyeote_place_alert_event_results (name, passed, detail)
select
  'target_can_record_arrival_event',
  count(*) = 1 and bool_and(event_type = 'arrived'),
  jsonb_agg(event_type)::text
from public.record_place_alert_event(
  (
    select id
    from public.place_alerts
    where name = 'Event Place'
    limit 1
  ),
  'arrived',
  now(),
  'arrival-dedupe',
  '{"source":"geofence"}'::jsonb
);

insert into gyeote_place_alert_event_results (name, passed, detail)
select
  'dedupe_keeps_single_event',
  count(*) = 1,
  count(*)::text
from public.record_place_alert_event(
  (
    select id
    from public.place_alerts
    where name = 'Event Place'
    limit 1
  ),
  'arrived',
  now(),
  'arrival-dedupe',
  '{"source":"retry"}'::jsonb
);

do $$
declare
  existing_alert_id uuid;
begin
  select id
    into existing_alert_id
  from public.place_alerts
  where name = 'Event Place'
  limit 1;

  perform public.record_place_alert_event(
    existing_alert_id,
    'departed',
    now(),
    'departure-disabled',
    '{}'::jsonb
  );

  insert into gyeote_place_alert_event_results (name, passed, detail)
  values ('disabled_event_type_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_event_results (name, passed, detail)
    values ('disabled_event_type_rejected', sqlerrm = 'place_alert_event_not_enabled', sqlerrm);
end $$;

set local "request.jwt.claim.sub" = '15151515-1515-4000-8000-000000000003';

do $$
declare
  existing_alert_id uuid;
begin
  select alert_id
    into existing_alert_id
  from gyeote_place_alert_event_fixture
  limit 1;

  perform public.record_place_alert_event(
    existing_alert_id,
    'arrived',
    now(),
    'outsider',
    '{}'::jsonb
  );

  insert into gyeote_place_alert_event_results (name, passed, detail)
  values ('outsider_event_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_event_results (name, passed, detail)
    values ('outsider_event_rejected', sqlerrm = 'place_alert_target_required', sqlerrm);
end $$;

reset role;

select
  bool_and(passed) as all_place_alert_event_tests_passed,
  jsonb_object_agg(name, passed order by name) as assertions,
  jsonb_object_agg(name, detail order by name) filter (where not passed) as failures
from gyeote_place_alert_event_results;

rollback;
