select
  to_regclass('public.check_in_events') is not null as check_in_events_installed,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'perform_check_in'
  ) as perform_check_in_installed,
  exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname = 'list_circle_check_ins'
  ) as list_circle_check_ins_installed,
  exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'latest_locations'
      and policyname = 'latest_locations_select_self'
      and qual = '(profile_id = auth.uid())'
  ) as latest_locations_raw_select_hardened,
  not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'latest_locations'
      and policyname = 'latest_locations_select_authorized'
  ) as broad_latest_locations_select_removed;
