-- Read-only verification for migration 011.
select
  to_regprocedure(
    'public.create_place_alert_with_targets(uuid, text, double precision, double precision, int, uuid[], boolean, boolean, boolean, boolean, jsonb)'
  ) is not null as place_alert_create_rpc_installed,
  has_function_privilege(
    'authenticated',
    'public.create_place_alert_with_targets(uuid, text, double precision, double precision, int, uuid[], boolean, boolean, boolean, boolean, jsonb)',
    'EXECUTE'
  ) as place_alert_create_rpc_granted,
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'place_alerts'
      and policyname = 'place_alerts_no_client_insert'
      and cmd = 'INSERT'
      and with_check = 'false'
  ) as direct_place_alert_insert_blocked,
  not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'place_alerts'
      and policyname = 'place_alerts_insert_circle_members'
  ) as broad_place_alert_insert_removed,
  pg_get_functiondef(
    'public.create_place_alert_with_targets(uuid, text, double precision, double precision, int, uuid[], boolean, boolean, boolean, boolean, jsonb)'::regprocedure
  ) like '%place_alert_minor_guardian_required%' as minor_guardian_check_installed,
  pg_get_functiondef(
    'public.create_place_alert_with_targets(uuid, text, double precision, double precision, int, uuid[], boolean, boolean, boolean, boolean, jsonb)'::regprocedure
  ) like '%place_alert_target_not_shareable%' as shareability_check_installed;
