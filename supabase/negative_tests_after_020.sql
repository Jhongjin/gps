-- Rollback-only tests for account and history deletion.
-- The SELECT result is shown before ROLLBACK, and all fixture rows are discarded.

begin;

create temp table gyeote_deletion_results (
  name text primary key,
  passed boolean not null,
  detail text
) on commit drop;

grant all on table gyeote_deletion_results to authenticated;

insert into auth.users (id, aud, role, email, raw_user_meta_data)
values
  ('20202020-2020-4000-8000-000000000001', 'authenticated', 'authenticated', 'gyeote-del-a@example.invalid', '{"display_name":"A"}'::jsonb),
  ('20202020-2020-4000-8000-000000000002', 'authenticated', 'authenticated', 'gyeote-del-b@example.invalid', '{"display_name":"B"}'::jsonb);

-- B 는 A 를 보호자로 둔다. cascade 가 아닌 FK 가 삭제를 막지 않는지 본다.
update public.profiles set guardian_profile_id = '20202020-2020-4000-8000-000000000001'
 where id = '20202020-2020-4000-8000-000000000002';

insert into public.circles (id, name, created_by)
values ('20202020-2020-4000-8000-000000000101', 'Deletion', '20202020-2020-4000-8000-000000000001');

insert into public.circle_members (circle_id, profile_id, role)
values
  ('20202020-2020-4000-8000-000000000101', '20202020-2020-4000-8000-000000000001', 'owner'),
  ('20202020-2020-4000-8000-000000000101', '20202020-2020-4000-8000-000000000002', 'member');

insert into public.devices (id, profile_id, platform)
values ('20202020-2020-4000-8000-000000000201', '20202020-2020-4000-8000-000000000001', 'android');

insert into public.location_history (profile_id, source, shared_lat, shared_lng, accuracy_m, sharing_precision, recorded_at)
values
  ('20202020-2020-4000-8000-000000000001', 'gps', 37.5, 127.0, 10, 'balanced', now() - interval '5 minutes'),
  ('20202020-2020-4000-8000-000000000001', 'gps', 37.501, 127.001, 10, 'balanced', now() - interval '4 minutes'),
  ('20202020-2020-4000-8000-000000000002', 'gps', 37.6, 127.1, 10, 'balanced', now() - interval '3 minutes');

insert into public.latest_locations (profile_id, device_id, source, shared_lat, shared_lng, accuracy_m, sharing_precision, recorded_at)
values ('20202020-2020-4000-8000-000000000001', '20202020-2020-4000-8000-000000000201', 'gps', 37.501, 127.001, 10, 'balanced', now());

set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '20202020-2020-4000-8000-000000000001';

-- 내 기록만 지워지고, 남의 기록은 남는다.
insert into gyeote_deletion_results (name, passed, detail)
select 'history_delete_returns_own_rows', public.delete_my_location_history() = 3, 'expected 3';

reset role;

insert into gyeote_deletion_results (name, passed, detail)
select
  'history_delete_leaves_other_member',
  count(*) = 1,
  count(*)::text
from public.location_history
where profile_id = '20202020-2020-4000-8000-000000000002';

insert into gyeote_deletion_results (name, passed, detail)
select
  'history_delete_recorded_as_completed',
  count(*) = 1,
  count(*)::text
from public.data_requests
where profile_id = '20202020-2020-4000-8000-000000000001'
  and request_type = 'delete_history'
  and status = 'completed';

set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '20202020-2020-4000-8000-000000000001';

do $$
begin
  perform public.delete_my_account();
  insert into gyeote_deletion_results (name, passed, detail)
  values ('account_delete_succeeds_with_guardian_reference', true, null);
exception
  when others then
    insert into gyeote_deletion_results (name, passed, detail)
    values ('account_delete_succeeds_with_guardian_reference', false, sqlerrm);
end $$;

reset role;

insert into gyeote_deletion_results (name, passed, detail)
select 'account_delete_removes_auth_user', count(*) = 0, count(*)::text
from auth.users where id = '20202020-2020-4000-8000-000000000001';

insert into gyeote_deletion_results (name, passed, detail)
select 'account_delete_removes_profile', count(*) = 0, count(*)::text
from public.profiles where id = '20202020-2020-4000-8000-000000000001';

insert into gyeote_deletion_results (name, passed, detail)
select 'account_delete_removes_membership', count(*) = 0, count(*)::text
from public.circle_members where profile_id = '20202020-2020-4000-8000-000000000001';

insert into gyeote_deletion_results (name, passed, detail)
select 'account_delete_clears_guardian_reference_on_others', count(*) = 1, count(*)::text
from public.profiles
where id = '20202020-2020-4000-8000-000000000002' and guardian_profile_id is null;

insert into gyeote_deletion_results (name, passed, detail)
select 'account_delete_leaves_other_member', count(*) = 1, count(*)::text
from public.profiles where id = '20202020-2020-4000-8000-000000000002';

-- 인증 없이는 아무것도 못 지운다.
set local role authenticated;
set local row_security = on;
set local "request.jwt.claim.sub" = '';

do $$
begin
  perform public.delete_my_account();
  insert into gyeote_deletion_results (name, passed, detail)
  values ('unauthenticated_delete_rejected', false, 'unexpected success');
exception
  when others then
    insert into gyeote_deletion_results (name, passed, detail)
    values ('unauthenticated_delete_rejected', sqlerrm = 'not_authenticated', sqlerrm);
end $$;

reset role;

select
  bool_and(passed) as all_negative_tests_passed,
  jsonb_object_agg(name, passed order by name) as assertions,
  jsonb_object_agg(name, detail order by name) filter (where not passed) as failures
from gyeote_deletion_results;

rollback;
