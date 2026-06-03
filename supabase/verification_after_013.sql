-- Read-only verification for migration 013.
select
  to_regprocedure(
    'public.get_active_companion_route_tail(uuid, uuid, int, timestamptz)'
  ) is not null as active_companion_route_tail_rpc_installed,
  has_function_privilege(
    'authenticated',
    'public.get_active_companion_route_tail(uuid, uuid, int, timestamptz)',
    'EXECUTE'
  ) as active_companion_route_tail_rpc_granted,
  pg_get_functiondef(
    'public.get_active_companion_route_tail(uuid, uuid, int, timestamptz)'::regprocedure
  ) like '%lh.companion_session_id%' as route_tail_session_scoped,
  pg_get_functiondef(
    'public.get_active_companion_route_tail(uuid, uuid, int, timestamptz)'::regprocedure
  ) like '%cs.status = ''active''%' as route_tail_active_only,
  pg_get_functiondef(
    'public.get_active_companion_route_tail(uuid, uuid, int, timestamptz)'::regprocedure
  ) like '%viewer_member.can_view%' as route_tail_viewer_guard_installed;
