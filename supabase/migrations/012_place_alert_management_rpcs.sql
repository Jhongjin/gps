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
