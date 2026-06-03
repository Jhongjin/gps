create or replace function public.get_circle_member_route_tail(
  target_circle_id uuid,
  subject_profile_id uuid,
  route_limit int default 30,
  since_at timestamptz default (now() - interval '2 hours')
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
  with authorized_tail as (
    select
      lh.profile_id,
      lh.shared_lat,
      lh.shared_lng,
      lh.sharing_precision,
      lh.recorded_at
    from public.location_history lh
    join public.circle_members cm on cm.profile_id = lh.profile_id
    where cm.circle_id = target_circle_id
      and cm.removed_at is null
      and lh.profile_id = subject_profile_id
      and lh.shared_lat is not null
      and lh.shared_lng is not null
      and lh.recorded_at >= since_at
      and public.is_circle_member(target_circle_id, auth.uid())
      and (
        lh.profile_id = auth.uid()
        or public.can_view_profile_location(lh.profile_id, auth.uid())
      )
    order by lh.recorded_at desc
    limit least(greatest(route_limit, 1), 100)
  )
  select *
  from authorized_tail
  order by recorded_at asc;
$$;

grant execute on function public.get_circle_member_route_tail(uuid, uuid, int, timestamptz) to authenticated;

comment on function public.get_circle_member_route_tail(uuid, uuid, int, timestamptz) is
  'Returns a bounded shared-coordinate route tail for one member in an authorized circle. Raw coordinates stay server-side.';
