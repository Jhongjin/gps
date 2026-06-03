alter table public.consent_events
drop constraint if exists consent_events_event_type_check;

alter table public.consent_events
add constraint consent_events_event_type_check check (
  event_type in (
    'circle_created',
    'invite_created',
    'invite_accepted',
    'sharing_paused',
    'sharing_resumed',
    'precision_changed',
    'companion_started',
    'companion_consented',
    'companion_ended',
    'member_removed'
  )
);

create or replace function public.create_circle_with_owner(
  circle_name text default '가족 서클',
  circle_kind text default 'family'
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_circle_id uuid;
  normalized_name text;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  normalized_name := nullif(trim(circle_name), '');
  if normalized_name is null then
    normalized_name := '가족 서클';
  end if;

  insert into public.circles (
    name,
    circle_type,
    created_by
  )
  values (
    left(normalized_name, 80),
    coalesce(nullif(trim(circle_kind), ''), 'family'),
    auth.uid()
  )
  returning id into new_circle_id;

  insert into public.circle_members (
    circle_id,
    profile_id,
    role,
    can_view_location,
    joined_at,
    removed_at
  )
  values (
    new_circle_id,
    auth.uid(),
    'owner',
    true,
    now(),
    null
  );

  insert into public.sharing_policies (
    circle_id,
    profile_id,
    precision,
    enabled
  )
  values (
    new_circle_id,
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
    new_circle_id,
    'circle_created',
    jsonb_build_object('circleName', left(normalized_name, 80), 'circleKind', circle_kind)
  );

  return new_circle_id;
end;
$$;

grant execute on function public.create_circle_with_owner(text, text) to authenticated;

comment on function public.create_circle_with_owner(text, text) is 'Creates a circle, owner membership, default sharing policy, and consent event for the authenticated user.';
