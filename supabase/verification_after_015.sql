-- Read-only verification for migration 015.
select
  to_regprocedure(
    'public.record_place_alert_event(uuid, text, timestamptz, text, jsonb)'
  ) is not null as place_alert_event_ingest_rpc_installed,
  has_function_privilege(
    'authenticated',
    'public.record_place_alert_event(uuid, text, timestamptz, text, jsonb)',
    'EXECUTE'
  ) as place_alert_event_ingest_rpc_granted,
  pg_get_functiondef(
    'public.record_place_alert_event(uuid, text, timestamptz, text, jsonb)'::regprocedure
  ) like '%place_alert_target_required%' as event_target_guard_installed,
  pg_get_functiondef(
    'public.record_place_alert_event(uuid, text, timestamptz, text, jsonb)'::regprocedure
  ) like '%place_alert_event_not_enabled%' as event_toggle_guard_installed,
  pg_get_functiondef(
    'public.record_place_alert_event(uuid, text, timestamptz, text, jsonb)'::regprocedure
  ) like '%on conflict (place_alert_id, subject_profile_id, dedupe_key)%' as event_dedupe_installed;
