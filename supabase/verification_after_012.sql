-- Read-only verification for migration 012.
select
  to_regprocedure(
    'public.set_place_alert_enabled(uuid, boolean)'
  ) is not null as place_alert_toggle_rpc_installed,
  has_function_privilege(
    'authenticated',
    'public.set_place_alert_enabled(uuid, boolean)',
    'EXECUTE'
  ) as place_alert_toggle_rpc_granted,
  to_regprocedure(
    'public.delete_place_alert(uuid)'
  ) is not null as place_alert_delete_rpc_installed,
  has_function_privilege(
    'authenticated',
    'public.delete_place_alert(uuid)',
    'EXECUTE'
  ) as place_alert_delete_rpc_granted,
  not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'place_alerts'
      and cmd in ('UPDATE', 'DELETE', 'ALL')
  ) as direct_place_alert_mutation_blocked,
  pg_get_functiondef(
    'public.set_place_alert_enabled(uuid, boolean)'::regprocedure
  ) like '%place_alert_owner_required%' as toggle_owner_guard_installed,
  pg_get_functiondef(
    'public.delete_place_alert(uuid)'::regprocedure
  ) like '%place_alert_owner_required%' as delete_owner_guard_installed;
