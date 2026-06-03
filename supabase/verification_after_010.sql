-- Read-only verification for migration 010.
select
  pg_get_functiondef('public.perform_check_in(uuid, uuid, text, text)'::regprocedure)
    like '%linked_companion_session_id%' as check_in_session_link_guard_installed,
  pg_get_functiondef('public.perform_check_in(uuid, uuid, text, text)'::regprocedure)
    like '%cs.subject_profile_id = current_user_id%' as check_in_session_subject_predicate_installed,
  pg_get_functiondef('public.perform_check_in(uuid, uuid, text, text)'::regprocedure)
    like '%companion_session_subject_required%' as check_in_session_error_installed,
  pg_get_functiondef('public.perform_check_in(uuid, uuid, text, text)'::regprocedure)
    like '%cs.expires_at > now()%' as check_in_session_expiry_guard_installed;
