-- Rollback-only RPC negative tests for place alert quiet-hours edits.
-- The SELECT result is shown before ROLLBACK, and all fixture rows are discarded.

begin;

create temp table gyeote_place_alert_quiet_results (
  name text primary key,
  passed boolean not null,
  detail text
) on commit drop;

grant all on table gyeote_place_alert_quiet_results to authenticated;

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  (
    '14141414-1414-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'gyeote-place-quiet-a@example.invalid',
    '{"display_name":"Quiet A"}'::jsonb
  ),
  (
    '14141414-1414-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'gyeote-place-quiet-b@example.invalid',
    '{"display_name":"Quiet B"}'::jsonb
  );

insert into public.circles (id, name, created_by)
values ('14141414-1414-4000-8000-000000000101', 'Quiet Circle', '14141414-1414-4000-8000-000000000001');

insert into public.circle_members (circle_id, profile_id, role, can_view_location)
values
  ('14141414-1414-4000-8000-000000000101', '14141414-1414-4000-8000-000000000001', 'owner', true),
  ('14141414-1414-4000-8000-000000000101', '14141414-1414-4000-8000-000000000002', 'member', true);

insert into public.sharing_policies (circle_id, profile_id, precision, enabled)
values
  ('14141414-1414-4000-8000-000000000101', '14141414-1414-4000-8000-000000000001', 'balanced', true),
  ('14141414-1414-4000-8000-000000000101', '14141414-1414-4000-8000-000000000002', 'balanced', true);

set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '14141414-1414-4000-8000-000000000001';

insert into gyeote_place_alert_quiet_results (name, passed, detail)
select
  'creator_can_create_alert',
  count(*) = 1,
  count(*)::text
from public.create_place_alert_with_targets(
  '14141414-1414-4000-8000-000000000101',
  'Quiet Place',
  37.501,
  127.039,
  300,
  array['14141414-1414-4000-8000-000000000002']::uuid[],
  true,
  true,
  false,
  false,
  '{}'::jsonb
);

insert into gyeote_place_alert_quiet_results (name, passed, detail)
select
  'creator_can_set_quiet_hours',
  count(*) = 1 and bool_and(quiet_hours ->> 'label' = '야간'),
  jsonb_agg(quiet_hours)::text
from public.set_place_alert_quiet_hours(
  (
    select id
    from public.place_alerts
    where name = 'Quiet Place'
    limit 1
  ),
  '{"enabled":true,"start":"22:00","end":"07:00","timeZone":"Asia/Seoul","label":"야간"}'::jsonb
);

do $$
declare
  existing_alert_id uuid;
begin
  select id
    into existing_alert_id
  from public.place_alerts
  where name = 'Quiet Place'
  limit 1;

  perform public.set_place_alert_quiet_hours(existing_alert_id, '[]'::jsonb);

  insert into gyeote_place_alert_quiet_results (name, passed, detail)
  values ('invalid_quiet_hours_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_quiet_results (name, passed, detail)
    values ('invalid_quiet_hours_rejected', sqlerrm = 'invalid_place_alert_quiet_hours', sqlerrm);
end $$;

set local "request.jwt.claim.sub" = '14141414-1414-4000-8000-000000000002';

do $$
declare
  existing_alert_id uuid;
begin
  select id
    into existing_alert_id
  from public.place_alerts
  where name = 'Quiet Place'
  limit 1;

  perform public.set_place_alert_quiet_hours(existing_alert_id, '{}'::jsonb);

  insert into gyeote_place_alert_quiet_results (name, passed, detail)
  values ('non_creator_quiet_hours_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_place_alert_quiet_results (name, passed, detail)
    values ('non_creator_quiet_hours_rejected', sqlerrm = 'place_alert_owner_required', sqlerrm);
end $$;

reset role;

select
  bool_and(passed) as all_place_alert_quiet_hours_tests_passed,
  jsonb_object_agg(name, passed order by name) as assertions,
  jsonb_object_agg(name, detail order by name) filter (where not passed) as failures
from gyeote_place_alert_quiet_results;

rollback;
