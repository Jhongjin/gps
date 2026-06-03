drop policy if exists "place_alerts_insert_circle_members" on public.place_alerts;
drop policy if exists "place_alerts_no_client_insert" on public.place_alerts;

create policy "place_alerts_no_client_insert" on public.place_alerts
for insert with check (false);

comment on policy "place_alerts_no_client_insert" on public.place_alerts is
  'Clients must create place alerts through create_place_alert_with_targets so targets and minor guard rules are validated atomically.';

create or replace function public.create_place_alert_with_targets(
  target_circle_id uuid,
  alert_name text,
  target_center_lat double precision,
  target_center_lng double precision,
  target_radius_m int,
  target_profile_ids uuid[],
  notify_arrival boolean default true,
  notify_departure boolean default true,
  notify_late boolean default false,
  notify_long_stay boolean default false,
  quiet_hours jsonb default '{}'::jsonb
)
returns table (
  id uuid,
  circle_id uuid,
  name text,
  center_lat double precision,
  center_lng double precision,
  radius_m int,
  notify_on_arrival boolean,
  notify_on_departure boolean,
  notify_on_late boolean,
  notify_on_long_stay boolean,
  enabled boolean,
  target_count int,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  normalized_name text := btrim(alert_name);
  requested_target_count int;
  saved_alert public.place_alerts%rowtype;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_circle_member(target_circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  if normalized_name is null or length(normalized_name) < 1 or length(normalized_name) > 60 then
    raise exception 'invalid_place_alert_name';
  end if;

  if target_center_lat is null or target_center_lng is null
    or target_center_lat < -90 or target_center_lat > 90
    or target_center_lng < -180 or target_center_lng > 180 then
    raise exception 'invalid_place_alert_center';
  end if;

  if target_radius_m is null or target_radius_m < 50 or target_radius_m > 5000 then
    raise exception 'invalid_place_alert_radius';
  end if;

  if not (
    notify_arrival
    or notify_departure
    or notify_late
    or notify_long_stay
  ) then
    raise exception 'place_alert_event_required';
  end if;

  if quiet_hours is null or jsonb_typeof(quiet_hours) <> 'object' then
    raise exception 'invalid_place_alert_quiet_hours';
  end if;

  with requested_targets as (
    select distinct unnest(coalesce(target_profile_ids, array[]::uuid[])) as profile_id
  )
  select count(*)
    into requested_target_count
  from requested_targets;

  if requested_target_count < 1 then
    raise exception 'place_alert_target_required';
  end if;

  if requested_target_count > 10 then
    raise exception 'place_alert_target_limit_exceeded';
  end if;

  if exists (
    with requested_targets as (
      select distinct unnest(target_profile_ids) as profile_id
    )
    select 1
    from requested_targets rt
    where not public.is_circle_member(target_circle_id, rt.profile_id)
  ) then
    raise exception 'place_alert_target_not_circle_member';
  end if;

  if exists (
    with requested_targets as (
      select distinct unnest(target_profile_ids) as profile_id
    )
    select 1
    from requested_targets rt
    join public.profiles p on p.id = rt.profile_id
    where p.is_minor
      and rt.profile_id <> current_user_id
      and coalesce(p.guardian_profile_id, '00000000-0000-0000-0000-000000000000'::uuid) <> current_user_id
  ) then
    raise exception 'place_alert_minor_guardian_required';
  end if;

  if exists (
    with requested_targets as (
      select distinct unnest(target_profile_ids) as profile_id
    )
    select 1
    from requested_targets rt
    where rt.profile_id <> current_user_id
      and not public.can_view_profile_location(rt.profile_id, current_user_id)
  ) then
    raise exception 'place_alert_target_not_shareable';
  end if;

  insert into public.place_alerts (
    circle_id,
    created_by,
    name,
    center_lat,
    center_lng,
    radius_m,
    notify_on_arrival,
    notify_on_departure,
    notify_on_late,
    notify_on_long_stay,
    quiet_hours
  )
  values (
    target_circle_id,
    current_user_id,
    normalized_name,
    target_center_lat,
    target_center_lng,
    target_radius_m,
    notify_arrival,
    notify_departure,
    notify_late,
    notify_long_stay,
    quiet_hours
  )
  returning * into saved_alert;

  insert into public.place_alert_targets (place_alert_id, profile_id)
  select saved_alert.id, rt.profile_id
  from (
    select distinct unnest(target_profile_ids) as profile_id
  ) rt;

  return query
  select
    saved_alert.id,
    saved_alert.circle_id,
    saved_alert.name,
    saved_alert.center_lat,
    saved_alert.center_lng,
    saved_alert.radius_m,
    saved_alert.notify_on_arrival,
    saved_alert.notify_on_departure,
    saved_alert.notify_on_late,
    saved_alert.notify_on_long_stay,
    saved_alert.enabled,
    requested_target_count,
    saved_alert.created_at;
end;
$$;

grant execute on function public.create_place_alert_with_targets(
  uuid,
  text,
  double precision,
  double precision,
  int,
  uuid[],
  boolean,
  boolean,
  boolean,
  boolean,
  jsonb
) to authenticated;

comment on function public.create_place_alert_with_targets(
  uuid,
  text,
  double precision,
  double precision,
  int,
  uuid[],
  boolean,
  boolean,
  boolean,
  boolean,
  jsonb
) is
  'Atomically creates a place alert and validated targets. Targets must be same-circle members; minor targets require self or guardian ownership.';
