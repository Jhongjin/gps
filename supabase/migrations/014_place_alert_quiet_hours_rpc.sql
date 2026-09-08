-- 입력 인자 이름이 반환 테이블의 quiet_hours 칼럼과 겹치면 PL/pgSQL 이
-- "parameter name used more than once" 로 컴파일을 거부한다. 이 파일은
-- 프로덕션에 올라간 적이 없어서 그 사실이 tools/check_migrations_local.py 로
-- 빈 클러스터에 적용해 보기 전까지 드러나지 않았다.
create or replace function public.set_place_alert_quiet_hours(
  alert_id uuid,
  new_quiet_hours jsonb
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
  normalized_quiet_hours jsonb := coalesce(new_quiet_hours, '{}'::jsonb);
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
