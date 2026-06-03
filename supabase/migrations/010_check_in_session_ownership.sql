create or replace function public.perform_check_in(
  target_circle_id uuid,
  target_companion_session_id uuid default null,
  target_status text default 'safe_arrived',
  client_dedupe_key text default null
)
returns table (
  id uuid,
  circle_id uuid,
  actor_profile_id uuid,
  subject_profile_id uuid,
  status text,
  sharing_precision public.sharing_precision,
  companion_session_id uuid,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  current_precision public.sharing_precision;
  linked_companion_session_id uuid;
  resolved_dedupe_key text;
  saved_event public.check_in_events%rowtype;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_circle_member(target_circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  if target_status not in ('safe_arrived', 'needs_check', 'signal_weak') then
    raise exception 'invalid_check_in_status';
  end if;

  select sp.precision
    into current_precision
  from public.sharing_policies sp
  where sp.circle_id = target_circle_id
    and sp.profile_id = current_user_id;

  current_precision := coalesce(current_precision, 'balanced'::public.sharing_precision);

  if target_companion_session_id is not null then
    select cs.id
      into linked_companion_session_id
    from public.companion_sessions cs
    where cs.id = target_companion_session_id
      and cs.circle_id = target_circle_id
      and cs.subject_profile_id = current_user_id
      and cs.status in ('pending'::public.companion_status, 'active'::public.companion_status)
      and cs.expires_at > now();

    if linked_companion_session_id is null then
      raise exception 'companion_session_subject_required';
    end if;

    update public.companion_sessions
      set status = 'ended'::public.companion_status,
          ended_at = coalesce(ended_at, now()),
          end_reason = 'manual_check_in'
    where public.companion_sessions.id = linked_companion_session_id;
  end if;

  resolved_dedupe_key := coalesce(
    nullif(client_dedupe_key, ''),
    'manual:' || target_circle_id::text || ':' || current_user_id::text || ':' ||
      to_char(date_trunc('minute', now()), 'YYYYMMDDHH24MI')
  );

  insert into public.check_in_events (
    circle_id,
    actor_profile_id,
    subject_profile_id,
    companion_session_id,
    status,
    sharing_precision,
    dedupe_key,
    metadata
  )
  values (
    target_circle_id,
    current_user_id,
    current_user_id,
    linked_companion_session_id,
    target_status,
    current_precision,
    resolved_dedupe_key,
    jsonb_build_object('source', 'manual')
  )
  on conflict on constraint check_in_events_circle_id_subject_profile_id_dedupe_key_key
  do update set
    status = excluded.status,
    sharing_precision = excluded.sharing_precision,
    companion_session_id = coalesce(excluded.companion_session_id, public.check_in_events.companion_session_id),
    expires_at = excluded.expires_at
  returning * into saved_event;

  return query
  select
    saved_event.id,
    saved_event.circle_id,
    saved_event.actor_profile_id,
    saved_event.subject_profile_id,
    saved_event.status,
    saved_event.sharing_precision,
    saved_event.companion_session_id,
    saved_event.created_at;
end;
$$;

grant execute on function public.perform_check_in(uuid, uuid, text, text) to authenticated;

comment on function public.perform_check_in(uuid, uuid, text, text) is
  'Creates a coordinate-free check-in event and ends the caller subject companion session only when the supplied session belongs to the caller and is still pending or active.';
