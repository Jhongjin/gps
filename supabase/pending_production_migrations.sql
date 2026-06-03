-- Pending SQL Editor bundle.
-- Apply in order: 012_place_alert_management_rpcs.sql, 013_active_companion_route_tail_rpc.sql, then 014_place_alert_quiet_hours_rpc.sql

create or replace function public.set_place_alert_enabled(
  alert_id uuid,
  is_enabled boolean
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
  target_alert public.place_alerts%rowtype;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if is_enabled is null then
    raise exception 'invalid_place_alert_enabled';
  end if;

  select *
    into target_alert
  from public.place_alerts
  where place_alerts.id = alert_id;

  if target_alert.id is null then
    raise exception 'place_alert_not_found';
  end if;

  if not public.is_circle_member(target_alert.circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  if target_alert.created_by <> current_user_id then
    raise exception 'place_alert_owner_required';
  end if;

  update public.place_alerts
  set enabled = is_enabled,
      updated_at = now()
  where place_alerts.id = alert_id
  returning * into target_alert;

  return query
  select
    target_alert.id,
    target_alert.circle_id,
    target_alert.name,
    target_alert.center_lat,
    target_alert.center_lng,
    target_alert.radius_m,
    target_alert.notify_on_arrival,
    target_alert.notify_on_departure,
    target_alert.notify_on_late,
    target_alert.notify_on_long_stay,
    target_alert.enabled,
    (
      select count(*)::int
      from public.place_alert_targets pat
      where pat.place_alert_id = target_alert.id
    ) as target_count,
    target_alert.created_at;
end;
$$;

grant execute on function public.set_place_alert_enabled(uuid, boolean) to authenticated;

comment on function public.set_place_alert_enabled(uuid, boolean) is
  'Creator-scoped place alert pause/resume RPC. Direct client updates remain blocked by RLS.';

create or replace function public.delete_place_alert(
  alert_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target_alert public.place_alerts%rowtype;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  select *
    into target_alert
  from public.place_alerts
  where place_alerts.id = alert_id;

  if target_alert.id is null then
    raise exception 'place_alert_not_found';
  end if;

  if not public.is_circle_member(target_alert.circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  if target_alert.created_by <> current_user_id then
    raise exception 'place_alert_owner_required';
  end if;

  delete from public.place_alerts
  where place_alerts.id = alert_id;

  return alert_id;
end;
$$;

grant execute on function public.delete_place_alert(uuid) to authenticated;

comment on function public.delete_place_alert(uuid) is
  'Creator-scoped place alert deletion RPC. Targets and events cascade through foreign keys.';

-- 013_active_companion_route_tail_rpc.sql
create or replace function public.get_active_companion_route_tail(
  target_session_id uuid,
  subject_profile_id uuid,
  route_limit int default 60,
  since_at timestamptz default (now() - interval '45 minutes')
)
returns table (
  profile_id uuid,
  shared_lat double precision,
  shared_lng double precision,
  sharing_precision public.sharing_precision,
  recorded_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  with session_scope as (
    select
      cs.id,
      coalesce(cs.started_at, cs.created_at) as started_boundary
    from public.companion_sessions cs
    join public.companion_session_members subject_member
      on subject_member.session_id = cs.id
      and subject_member.profile_id = subject_profile_id
    join public.companion_session_members viewer_member
      on viewer_member.session_id = cs.id
      and viewer_member.profile_id = auth.uid()
    where cs.id = target_session_id
      and cs.subject_profile_id = subject_profile_id
      and cs.status = 'active'
      and cs.expires_at > now()
      and subject_member.consented_at is not null
      and subject_member.revoked_at is null
      and viewer_member.consented_at is not null
      and viewer_member.revoked_at is null
      and viewer_member.can_view
  ),
  authorized_tail as (
    select
      lh.profile_id,
      lh.shared_lat,
      lh.shared_lng,
      lh.sharing_precision,
      lh.recorded_at
    from public.location_history lh
    join session_scope ss on ss.id = lh.companion_session_id
    where lh.profile_id = subject_profile_id
      and lh.shared_lat is not null
      and lh.shared_lng is not null
      and lh.recorded_at >= coalesce(since_at, now() - interval '45 minutes')
      and lh.recorded_at >= ss.started_boundary
    order by lh.recorded_at desc
    limit least(greatest(coalesce(route_limit, 60), 1), 200)
  )
  select *
  from authorized_tail
  order by recorded_at asc;
$$;

grant execute on function public.get_active_companion_route_tail(uuid, uuid, int, timestamptz) to authenticated;

comment on function public.get_active_companion_route_tail(uuid, uuid, int, timestamptz) is
  'Returns session-scoped shared-coordinate route samples only while the companion session is active and both participants have consented.';

-- 014_place_alert_quiet_hours_rpc.sql
create or replace function public.set_place_alert_quiet_hours(
  alert_id uuid,
  quiet_hours jsonb
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
  quiet_hours jsonb,
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
  target_alert public.place_alerts%rowtype;
  normalized_quiet_hours jsonb := coalesce(quiet_hours, '{}'::jsonb);
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if jsonb_typeof(normalized_quiet_hours) <> 'object' then
    raise exception 'invalid_place_alert_quiet_hours';
  end if;

  select *
    into target_alert
  from public.place_alerts
  where place_alerts.id = alert_id;

  if target_alert.id is null then
    raise exception 'place_alert_not_found';
  end if;

  if not public.is_circle_member(target_alert.circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  if target_alert.created_by <> current_user_id then
    raise exception 'place_alert_owner_required';
  end if;

  update public.place_alerts
  set quiet_hours = normalized_quiet_hours,
      updated_at = now()
  where place_alerts.id = alert_id
  returning * into target_alert;

  return query
  select
    target_alert.id,
    target_alert.circle_id,
    target_alert.name,
    target_alert.center_lat,
    target_alert.center_lng,
    target_alert.radius_m,
    target_alert.notify_on_arrival,
    target_alert.notify_on_departure,
    target_alert.notify_on_late,
    target_alert.notify_on_long_stay,
    target_alert.quiet_hours,
    target_alert.enabled,
    (
      select count(*)::int
      from public.place_alert_targets pat
      where pat.place_alert_id = target_alert.id
    ) as target_count,
    target_alert.created_at;
end;
$$;

grant execute on function public.set_place_alert_quiet_hours(uuid, jsonb) to authenticated;

comment on function public.set_place_alert_quiet_hours(uuid, jsonb) is
  'Creator-scoped quiet-hours update RPC for saved place alerts. Direct client updates remain blocked by RLS.';
