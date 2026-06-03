-- Read-only verification for production project usetuwqbzkmywmtgwwdx.
-- Expected result: every *_ok column is true and missing_required_objects is empty.

with required_objects(name, ok) as (
  values
    ('profiles_table', to_regclass('public.profiles') is not null),
    ('circles_table', to_regclass('public.circles') is not null),
    ('circle_members_table', to_regclass('public.circle_members') is not null),
    ('devices_table', to_regclass('public.devices') is not null),
    ('latest_locations_table', to_regclass('public.latest_locations') is not null),
    ('location_history_table', to_regclass('public.location_history') is not null),
    ('create_circle_with_owner_rpc', to_regprocedure('public.create_circle_with_owner(text, text)') is not null),
    ('get_circle_latest_locations_rpc', to_regprocedure('public.get_circle_latest_locations(uuid)') is not null),
    ('get_circle_member_route_tail_rpc', to_regprocedure('public.get_circle_member_route_tail(uuid, uuid, int, timestamp with time zone)') is not null),
    ('location_history_idempotency_idx', to_regclass('public.location_history_profile_idempotency_idx') is not null),
    (
      'latest_locations_update_policy',
      exists (
        select 1
        from pg_policies
        where schemaname = 'public'
          and tablename = 'latest_locations'
          and policyname = 'latest_locations_owner_registered_device_update'
          and cmd = 'UPDATE'
          and qual like '%profile_id = auth.uid()%'
          and with_check like '%devices%'
      )
    ),
    (
      'route_tail_execute_grant',
      has_function_privilege(
        'authenticated',
        'public.get_circle_member_route_tail(uuid, uuid, int, timestamp with time zone)',
        'EXECUTE'
      )
    )
)
select
  count(*) filter (where ok) as installed_count,
  count(*) filter (where not ok) as missing_count,
  array_agg(name order by name) filter (where not ok) as missing_required_objects,
  bool_and(ok) as all_required_objects_ok
from required_objects;
