create or replace function public.create_circle_invite(
  target_circle_id uuid,
  invite_max_uses int default 1,
  invite_ttl interval default interval '24 hours'
)
returns table (
  invite_id uuid,
  raw_invite_token text,
  code_hint text,
  expires_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  token text;
  token_hash text;
  hint text;
  expiry timestamptz;
  created_invite_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if invite_max_uses < 1 or invite_max_uses > 10 then
    raise exception 'invalid_invite_use_limit';
  end if;

  if not public.is_circle_member(target_circle_id, auth.uid()) then
    raise exception 'not_circle_member';
  end if;

  token := encode(gen_random_bytes(24), 'hex');
  token_hash := encode(digest(token, 'sha256'), 'hex');
  hint := upper(substr(token, 1, 6));
  expiry := now() + invite_ttl;

  insert into public.circle_invitations (
    circle_id,
    invited_by,
    invite_code_hint,
    invite_token_hash,
    max_uses,
    expires_at
  )
  values (
    target_circle_id,
    auth.uid(),
    hint,
    token_hash,
    invite_max_uses,
    expiry
  )
  returning id into created_invite_id;

  insert into public.consent_events (
    actor_profile_id,
    circle_id,
    event_type,
    metadata
  )
  values (
    auth.uid(),
    target_circle_id,
    'invite_created',
    jsonb_build_object('inviteId', created_invite_id, 'maxUses', invite_max_uses)
  );

  return query select created_invite_id, token, hint, expiry;
end;
$$;

create or replace function public.accept_circle_invite(raw_invite_token text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  token_hash text;
  invite_row public.circle_invitations%rowtype;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  token_hash := encode(digest(raw_invite_token, 'sha256'), 'hex');

  select *
  into invite_row
  from public.circle_invitations
  where invite_token_hash = token_hash
    and status = 'pending'
    and revoked_at is null
    and expires_at > now()
    and use_count < max_uses
  for update;

  if invite_row.id is null then
    raise exception 'invalid_or_expired_invite';
  end if;

  insert into public.circle_members (
    circle_id,
    profile_id,
    role,
    can_view_location,
    joined_at,
    removed_at
  )
  values (
    invite_row.circle_id,
    auth.uid(),
    'member',
    true,
    now(),
    null
  )
  on conflict (circle_id, profile_id)
  do update set
    removed_at = null,
    joined_at = now();

  update public.circle_invitations
  set
    use_count = use_count + 1,
    accepted_by = auth.uid(),
    accepted_at = now(),
    status = case when use_count + 1 >= max_uses then 'accepted'::public.invitation_status else status end
  where id = invite_row.id;

  insert into public.sharing_policies (
    circle_id,
    profile_id,
    precision,
    enabled
  )
  values (
    invite_row.circle_id,
    auth.uid(),
    'balanced',
    true
  )
  on conflict (circle_id, profile_id) do nothing;

  insert into public.consent_events (
    actor_profile_id,
    subject_profile_id,
    circle_id,
    event_type,
    metadata
  )
  values (
    auth.uid(),
    auth.uid(),
    invite_row.circle_id,
    'invite_accepted',
    jsonb_build_object('inviteId', invite_row.id)
  );

  return invite_row.circle_id;
end;
$$;

create or replace function public.record_viewer_log(
  target_profile_id uuid,
  target_circle_id uuid,
  viewed_precision public.sharing_precision
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  log_id uuid;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  if not public.can_view_profile_location(target_profile_id, auth.uid()) then
    raise exception 'location_view_not_allowed';
  end if;

  insert into public.viewer_logs (
    viewed_profile_id,
    viewer_profile_id,
    circle_id,
    precision
  )
  values (
    target_profile_id,
    auth.uid(),
    target_circle_id,
    viewed_precision
  )
  returning id into log_id;

  return log_id;
end;
$$;

comment on function public.create_circle_invite(uuid, int, interval) is 'Creates a one-time raw invite token response and stores only its hash.';
comment on function public.accept_circle_invite(text) is 'Accepts an invite by raw token and atomically creates circle membership.';
comment on function public.record_viewer_log(uuid, uuid, public.sharing_precision) is 'Server-side append-only viewer log writer used because client insert is blocked by RLS.';

create or replace function public.get_circle_latest_locations(target_circle_id uuid)
returns table (
  profile_id uuid,
  display_name text,
  shared_lat double precision,
  shared_lng double precision,
  sharing_precision public.sharing_precision,
  accuracy_m double precision,
  battery_percent int,
  recorded_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    ll.profile_id,
    p.display_name,
    ll.shared_lat,
    ll.shared_lng,
    ll.sharing_precision,
    ll.accuracy_m,
    ll.battery_percent,
    ll.recorded_at
  from public.latest_locations ll
  join public.circle_members cm on cm.profile_id = ll.profile_id
  join public.profiles p on p.id = ll.profile_id
  where cm.circle_id = target_circle_id
    and cm.removed_at is null
    and public.is_circle_member(target_circle_id, auth.uid())
    and (
      ll.profile_id = auth.uid()
      or public.can_view_profile_location(ll.profile_id, auth.uid())
    );
$$;

comment on function public.get_circle_latest_locations(uuid) is 'Returns latest shared coordinates scoped to one authorized circle.';
