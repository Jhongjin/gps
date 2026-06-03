-- Rollback-only RLS and RPC negative tests for place alert creation.
-- The SELECT result is shown before ROLLBACK, and all fixture rows are discarded.

begin;

create temp table gyeote_place_alert_results (
  name text primary key,
  passed boolean not null,
  detail text
) on commit drop;

grant all on table gyeote_place_alert_results to authenticated;

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  (
    '11111111-1111-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'gyeote-place-a@example.invalid',
    '{"display_name":"Place A"}'::jsonb
  ),
  (
    '11111111-1111-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'gyeote-place-b@example.invalid',
    '{"display_name":"Place B"}'::jsonb
  ),
  (
    '11111111-1111-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'gyeote-place-c@example.invalid',
    '{"display_name":"Place C"}'::jsonb
  ),
  (
    '11111111-1111-4000-8000-000000000004',
    'authenticated',
    'authenticated',
    'gyeote-place-minor-guarded@example.invalid',
    '{"display_name":"Guarded Minor"}'::jsonb
  ),
  (
    '11111111-1111-4000-8000-000000000005',
    'authenticated',
    'authenticated',
    'gyeote-place-minor-other@example.invalid',
    '{"display_name":"Other Minor"}'::jsonb
  );

update public.profiles
set is_minor = true,
    guardian_profile_id = '11111111-1111-4000-8000-000000000001'
where id = '11111111-1111-4000-8000-000000000004';

update public.profiles
set is_minor = true,
    guardian_profile_id = '11111111-1111-4000-8000-000000000003'
where id = '11111111-1111-4000-8000-000000000005';

insert into public.circles (id, name, created_by)
values
  ('11111111-1111-4000-8000-000000000101', 'Place Circle A', '11111111-1111-4000-8000-000000000001'),
  ('11111111-1111-4000-8000-000000000102', 'Place Circle C', '11111111-1111-4000-8000-000000000003');

insert into public.circle_members (circle_id, profile_id, role, can_view_location)
values
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000001', 'owner', true),
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000002', 'member', true),
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000004', 'child', true),
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000005', 'child', true),
  ('11111111-1111-4000-8000-000000000102', '11111111-1111-4000-8000-000000000003', 'owner', true);

insert into public.sharing_policies (circle_id, profile_id, precision, enabled)
values
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000001', 'balanced', true),
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000002', 'balanced', true),
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000004', 'balanced', true),
  ('11111111-1111-4000-8000-000000000101', '11111111-1111-4000-8000-000000000005', 'balanced', true),
  ('11111111-1111-4000-8000-000000000102', '11111111-1111-4000-8000-000000000003', 'balanced', true);

set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '11111111-1111-4000-8000-000000000001';

insert into gyeote_place_alert_results (name, passed, detail)
select
  'creator_can_create_alert_for_shareable_member',
  count(*) = 1,
  count(*)::text
from public.create_place_alert_with_targets(
  '11111111-1111-4000-8000-000000000101',
  'School',
  37.501,
  127.039,
  300,
  array['11111111-1111-4000-8000-000000000002']::uuid[],
  true,
  true,
  false,
  false,
  '{}'::jsonb
);

insert into gyeote_place_alert_results (name, passed, detail)
select
  'creator_can_create_alert_for_guarded_minor',
  count(*) = 1,
  count(*)::text
from public.create_place_alert_with_targets(
  '11111111-1111-4000-8000-000000000101',
  'Academy',
  37.502,
  127.040,
  200,
  array['11111111-1111-4000-8000-000000000004']::uuid[],
  true,
  false,
  false,
  false,
  '{}'::jsonb
);

do $$
begin
  insert into public.place_alerts (
    circle_id,
    created_by,
    name,
    center_lat,
    center_lng,
    radius_m,
    notify_on_arrival,
    notify_on_departure
  )
  values (
    '11111111-1111-4000-8000-000000000101',
    '11111111-1111-4000-8000-000000000001',
    'Direct Insert',
    37.5,
    127.0,
    300,
    true,
    true
  );

  insert into gyeote_place_alert_results (name, passed, detail)
  values ('direct_place_alert_insert_blocked', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_results (name, passed, detail)
    values ('direct_place_alert_insert_blocked', sqlstate = '42501', sqlerrm);
end $$;

do $$
declare
  existing_alert_id uuid;
begin
  select id
    into existing_alert_id
  from public.place_alerts
  where name = 'School'
  limit 1;

  insert into public.place_alert_targets (place_alert_id, profile_id)
  values (existing_alert_id, '11111111-1111-4000-8000-000000000001');

  insert into gyeote_place_alert_results (name, passed, detail)
  values ('direct_place_alert_target_insert_blocked', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_results (name, passed, detail)
    values ('direct_place_alert_target_insert_blocked', sqlstate = '42501', sqlerrm);
end $$;

do $$
begin
  perform *
  from public.create_place_alert_with_targets(
    '11111111-1111-4000-8000-000000000101',
    'Outside Target',
    37.501,
    127.039,
    300,
    array['11111111-1111-4000-8000-000000000003']::uuid[],
    true,
    true,
    false,
    false,
    '{}'::jsonb
  );

  insert into gyeote_place_alert_results (name, passed, detail)
  values ('target_outside_circle_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_results (name, passed, detail)
    values ('target_outside_circle_rejected', sqlerrm = 'place_alert_target_not_circle_member', sqlerrm);
end $$;

do $$
begin
  perform *
  from public.create_place_alert_with_targets(
    '11111111-1111-4000-8000-000000000101',
    'Other Minor',
    37.501,
    127.039,
    300,
    array['11111111-1111-4000-8000-000000000005']::uuid[],
    true,
    true,
    false,
    false,
    '{}'::jsonb
  );

  insert into gyeote_place_alert_results (name, passed, detail)
  values ('unguarded_minor_target_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_results (name, passed, detail)
    values ('unguarded_minor_target_rejected', sqlerrm = 'place_alert_minor_guardian_required', sqlerrm);
end $$;

do $$
begin
  perform *
  from public.create_place_alert_with_targets(
    '11111111-1111-4000-8000-000000000101',
    'No Target',
    37.501,
    127.039,
    300,
    array[]::uuid[],
    true,
    true,
    false,
    false,
    '{}'::jsonb
  );

  insert into gyeote_place_alert_results (name, passed, detail)
  values ('empty_targets_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_results (name, passed, detail)
    values ('empty_targets_rejected', sqlerrm = 'place_alert_target_required', sqlerrm);
end $$;

set local "request.jwt.claim.sub" = '11111111-1111-4000-8000-000000000003';

do $$
begin
  perform *
  from public.create_place_alert_with_targets(
    '11111111-1111-4000-8000-000000000101',
    'Outsider',
    37.501,
    127.039,
    300,
    array['11111111-1111-4000-8000-000000000002']::uuid[],
    true,
    true,
    false,
    false,
    '{}'::jsonb
  );

  insert into gyeote_place_alert_results (name, passed, detail)
  values ('outsider_create_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_results (name, passed, detail)
    values ('outsider_create_rejected', sqlerrm = 'circle_membership_required', sqlerrm);
end $$;

reset role;

select
  bool_and(passed) as all_place_alert_tests_passed,
  jsonb_object_agg(name, passed order by name) as assertions,
  jsonb_object_agg(name, detail order by name) filter (where not passed) as failures
from gyeote_place_alert_results;

rollback;
