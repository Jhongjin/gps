create or replace function public.record_place_alert_event(
  alert_id uuid,
  event_kind text,
  event_occurred_at timestamptz default now(),
  client_dedupe_key text default null,
  event_metadata jsonb default '{}'::jsonb
)
returns table (
  id uuid,
  place_alert_id uuid,
  subject_profile_id uuid,
  event_type text,
  dedupe_key text,
  occurred_at timestamptz,
  delivered_at timestamptz,
  metadata jsonb
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_alert public.place_alerts%rowtype;
  normalized_event_type text := lower(btrim(event_kind));
  normalized_occurred_at timestamptz := coalesce(event_occurred_at, now());
  normalized_metadata jsonb := coalesce(event_metadata, '{}'::jsonb);
  resolved_dedupe_key text;
  saved_event public.place_alert_events%rowtype;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if normalized_event_type not in ('arrived', 'departed', 'late', 'long_stay') then
    raise exception 'invalid_place_alert_event_type';
  end if;

  if jsonb_typeof(normalized_metadata) <> 'object' then
    raise exception 'invalid_place_alert_event_metadata';
  end if;

  select *
    into target_alert
  from public.place_alerts
  where place_alerts.id = alert_id;

  if target_alert.id is null then
    raise exception 'place_alert_not_found';
  end if;

  if not target_alert.enabled then
    raise exception 'place_alert_disabled';
  end if;

  if not exists (
    select 1
    from public.place_alert_targets pat
    where pat.place_alert_id = target_alert.id
      and pat.profile_id = current_user_id
  ) then
    raise exception 'place_alert_target_required';
  end if;

  if normalized_event_type = 'arrived' and not target_alert.notify_on_arrival then
    raise exception 'place_alert_event_not_enabled';
  end if;

  if normalized_event_type = 'departed' and not target_alert.notify_on_departure then
    raise exception 'place_alert_event_not_enabled';
  end if;

  if normalized_event_type = 'late' and not target_alert.notify_on_late then
    raise exception 'place_alert_event_not_enabled';
  end if;

  if normalized_event_type = 'long_stay' and not target_alert.notify_on_long_stay then
    raise exception 'place_alert_event_not_enabled';
  end if;

  resolved_dedupe_key := coalesce(
    nullif(client_dedupe_key, ''),
    normalized_event_type || ':' || to_char(date_trunc('minute', normalized_occurred_at), 'YYYYMMDDHH24MI')
  );

  insert into public.place_alert_events (
    place_alert_id,
    subject_profile_id,
    event_type,
    dedupe_key,
    occurred_at,
    metadata
  )
  values (
    target_alert.id,
    current_user_id,
    normalized_event_type,
    resolved_dedupe_key,
    normalized_occurred_at,
    normalized_metadata
  )
  on conflict (place_alert_id, subject_profile_id, dedupe_key)
  do update set
    metadata = public.place_alert_events.metadata || excluded.metadata
  returning * into saved_event;

  return query
  select
    saved_event.id,
    saved_event.place_alert_id,
    saved_event.subject_profile_id,
    saved_event.event_type,
    saved_event.dedupe_key,
    saved_event.occurred_at,
    saved_event.delivered_at,
    saved_event.metadata;
end;
$$;

grant execute on function public.record_place_alert_event(uuid, text, timestamptz, text, jsonb) to authenticated;

comment on function public.record_place_alert_event(uuid, text, timestamptz, text, jsonb) is
  'Records coordinate-free place alert transitions for the authenticated target member with dedupe protection.';
