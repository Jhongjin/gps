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
