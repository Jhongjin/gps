-- Read-only verification for migration 014.
select
  to_regprocedure(
    'public.set_place_alert_quiet_hours(uuid, jsonb)'
  ) is not null as place_alert_quiet_hours_rpc_installed,
  has_function_privilege(
    'authenticated',
    'public.set_place_alert_quiet_hours(uuid, jsonb)',
    'EXECUTE'
  ) as place_alert_quiet_hours_rpc_granted,
  pg_get_functiondef(
    'public.set_place_alert_quiet_hours(uuid, jsonb)'::regprocedure
  ) like '%place_alert_owner_required%' as quiet_hours_owner_guard_installed,
  pg_get_functiondef(
    'public.set_place_alert_quiet_hours(uuid, jsonb)'::regprocedure
  ) like '%invalid_place_alert_quiet_hours%' as quiet_hours_shape_guard_installed;
