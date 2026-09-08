-- Rollback-only RLS and RPC negative tests for place alert management.
-- The SELECT result is shown before ROLLBACK, and all fixture rows are discarded.

begin;

create temp table gyeote_place_alert_management_results (
  name text primary key,
  passed boolean not null,
  detail text
) on commit drop;

grant all on table gyeote_place_alert_management_results to authenticated;

-- 서클 밖 사람은 RLS 때문에 알림 행 자체를 못 본다. 그 사람 역할로 id 를
-- 조회하면 null 이 나오고, RPC 는 place_alert_not_found 를 낸다 — 그건 RLS 가
-- 한 일이지 RPC 의 멤버십 검사가 한 일이 아니다. 검사하려는 것은 후자이므로
-- id 는 만든 사람이 볼 수 있을 때 미리 담아 둔다.
create temp table gyeote_place_alert_fixture (
  alert_id uuid not null
) on commit drop;

grant all on table gyeote_place_alert_fixture to authenticated;

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  (
    '12121212-1212-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'gyeote-place-mgmt-a@example.invalid',
    '{"display_name":"Place Mgmt A"}'::jsonb
  ),
  (
    '12121212-1212-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'gyeote-place-mgmt-b@example.invalid',
    '{"display_name":"Place Mgmt B"}'::jsonb
  ),
  (
    '12121212-1212-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'gyeote-place-mgmt-c@example.invalid',
    '{"display_name":"Place Mgmt C"}'::jsonb
  );

insert into public.circles (id, name, created_by)
values
  ('12121212-1212-4000-8000-000000000101', 'Place Management Circle', '12121212-1212-4000-8000-000000000001'),
  ('12121212-1212-4000-8000-000000000102', 'Other Circle', '12121212-1212-4000-8000-000000000003');

insert into public.circle_members (circle_id, profile_id, role, can_view_location)
values
  ('12121212-1212-4000-8000-000000000101', '12121212-1212-4000-8000-000000000001', 'owner', true),
  ('12121212-1212-4000-8000-000000000101', '12121212-1212-4000-8000-000000000002', 'member', true),
  ('12121212-1212-4000-8000-000000000102', '12121212-1212-4000-8000-000000000003', 'owner', true);

insert into public.sharing_policies (circle_id, profile_id, precision, enabled)
values
  ('12121212-1212-4000-8000-000000000101', '12121212-1212-4000-8000-000000000001', 'balanced', true),
  ('12121212-1212-4000-8000-000000000101', '12121212-1212-4000-8000-000000000002', 'balanced', true),
  ('12121212-1212-4000-8000-000000000102', '12121212-1212-4000-8000-000000000003', 'balanced', true);

set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '12121212-1212-4000-8000-000000000001';

insert into gyeote_place_alert_management_results (name, passed, detail)
select
  'creator_can_create_alert',
  count(*) = 1,
  count(*)::text
from public.create_place_alert_with_targets(
  '12121212-1212-4000-8000-000000000101',
  'School',
  37.501,
  127.039,
  300,
  array['12121212-1212-4000-8000-000000000002']::uuid[],
  true,
  true,
  false,
  false,
  '{}'::jsonb
);

insert into gyeote_place_alert_fixture (alert_id)
select id from public.place_alerts where name = 'School' limit 1;

do $$
declare
  existing_alert_id uuid;
  affected_count int;
  still_enabled boolean;
begin
  select id
    into existing_alert_id
  from public.place_alerts
  where name = 'School'
  limit 1;

  update public.place_alerts
  set enabled = false
  where id = existing_alert_id;

  get diagnostics affected_count = row_count;

  select enabled
    into still_enabled
  from public.place_alerts
  where id = existing_alert_id;

  insert into gyeote_place_alert_management_results (name, passed, detail)
  values (
    'direct_place_alert_update_blocked',
    affected_count = 0 and still_enabled = true,
    format('affected=%s enabled=%s', affected_count, still_enabled)
  );
exception
  when others then
    insert into gyeote_place_alert_management_results (name, passed, detail)
    values ('direct_place_alert_update_blocked', false, sqlerrm);
end $$;

do $$
declare
  existing_alert_id uuid;
  affected_count int;
  still_exists boolean;
begin
  select id
    into existing_alert_id
  from public.place_alerts
  where name = 'School'
  limit 1;

  delete from public.place_alerts
  where id = existing_alert_id;

  get diagnostics affected_count = row_count;

  select exists (
    select 1
    from public.place_alerts
    where id = existing_alert_id
  )
    into still_exists;

  insert into gyeote_place_alert_management_results (name, passed, detail)
  values (
    'direct_place_alert_delete_blocked',
    affected_count = 0 and still_exists = true,
    format('affected=%s exists=%s', affected_count, still_exists)
  );
exception
  when others then
    insert into gyeote_place_alert_management_results (name, passed, detail)
    values ('direct_place_alert_delete_blocked', false, sqlerrm);
end $$;

insert into gyeote_place_alert_management_results (name, passed, detail)
select
  'creator_can_pause_alert',
  count(*) = 1 and bool_and(enabled = false),
  jsonb_agg(enabled)::text
from public.set_place_alert_enabled(
  (
    select id
    from public.place_alerts
    where name = 'School'
    limit 1
  ),
  false
);

insert into gyeote_place_alert_management_results (name, passed, detail)
select
  'creator_can_resume_alert',
  count(*) = 1 and bool_and(enabled = true),
  jsonb_agg(enabled)::text
from public.set_place_alert_enabled(
  (
    select id
    from public.place_alerts
    where name = 'School'
    limit 1
  ),
  true
);

set local "request.jwt.claim.sub" = '12121212-1212-4000-8000-000000000002';

do $$
declare
  existing_alert_id uuid;
begin
  select id
    into existing_alert_id
  from public.place_alerts
  where name = 'School'
  limit 1;

  perform public.set_place_alert_enabled(existing_alert_id, false);

  insert into gyeote_place_alert_management_results (name, passed, detail)
  values ('non_creator_pause_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_management_results (name, passed, detail)
    values ('non_creator_pause_rejected', sqlerrm = 'place_alert_owner_required', sqlerrm);
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

  perform public.delete_place_alert(existing_alert_id);

  insert into gyeote_place_alert_management_results (name, passed, detail)
  values ('non_creator_delete_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_management_results (name, passed, detail)
    values ('non_creator_delete_rejected', sqlerrm = 'place_alert_owner_required', sqlerrm);
end $$;

set local "request.jwt.claim.sub" = '12121212-1212-4000-8000-000000000003';

do $$
declare
  existing_alert_id uuid;
begin
  select alert_id
    into existing_alert_id
  from gyeote_place_alert_fixture
  limit 1;

  perform public.set_place_alert_enabled(existing_alert_id, false);

  insert into gyeote_place_alert_management_results (name, passed, detail)
  values ('outsider_pause_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_management_results (name, passed, detail)
    values ('outsider_pause_rejected', sqlerrm = 'circle_membership_required', sqlerrm);
end $$;

set local "request.jwt.claim.sub" = '12121212-1212-4000-8000-000000000001';

insert into gyeote_place_alert_management_results (name, passed, detail)
select
  'creator_can_delete_alert',
  public.delete_place_alert(
    (
      select id
      from public.place_alerts
      where name = 'School'
      limit 1
    )
  ) is not null,
  'deleted';

insert into gyeote_place_alert_management_results (name, passed, detail)
select
  'delete_cascades_targets',
  count(*) = 0,
  count(*)::text
from public.place_alert_targets;

reset role;

select
  bool_and(passed) as all_place_alert_management_tests_passed,
  jsonb_object_agg(name, passed order by name) as assertions,
  jsonb_object_agg(name, detail order by name) filter (where not passed) as failures
from gyeote_place_alert_management_results;

rollback;
