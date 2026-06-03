-- Apply in the Supabase SQL Editor for project usetuwqbzkmywmtgwwdx.
-- Source migration:
-- - migrations/009_check_in_events.sql

create table if not exists public.check_in_events (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  actor_profile_id uuid not null references public.profiles (id) on delete cascade,
  subject_profile_id uuid not null references public.profiles (id) on delete cascade,
  companion_session_id uuid references public.companion_sessions (id) on delete set null,
  status text not null check (status in ('safe_arrived', 'needs_check', 'signal_weak')),
  sharing_precision public.sharing_precision not null default 'balanced',
  dedupe_key text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 days'),
  unique (circle_id, subject_profile_id, dedupe_key)
);

create index if not exists check_in_events_circle_created_idx
  on public.check_in_events (circle_id, created_at desc);

create index if not exists check_in_events_subject_created_idx
  on public.check_in_events (subject_profile_id, created_at desc);

alter table public.check_in_events enable row level security;

drop policy if exists "check_in_events_no_client_insert" on public.check_in_events;
drop policy if exists "check_in_events_no_client_update" on public.check_in_events;
drop policy if exists "check_in_events_no_client_delete" on public.check_in_events;

create policy "check_in_events_no_client_insert" on public.check_in_events
for insert with check (false);

create policy "check_in_events_no_client_update" on public.check_in_events
for update using (false) with check (false);

create policy "check_in_events_no_client_delete" on public.check_in_events
for delete using (false);

drop policy if exists "latest_locations_select_authorized" on public.latest_locations;
drop policy if exists "latest_locations_select_self" on public.latest_locations;

create policy "latest_locations_select_self" on public.latest_locations
for select using (profile_id = auth.uid());

comment on policy "latest_locations_select_self" on public.latest_locations is
  'Clients may read only their own raw latest row directly. Circle member reads must use shared-coordinate RPCs.';

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
    update public.companion_sessions
      set status = 'ended'::public.companion_status,
          ended_at = coalesce(ended_at, now()),
          end_reason = 'manual_check_in'
    where id = target_companion_session_id
      and circle_id = target_circle_id
      and subject_profile_id = current_user_id
      and status in ('pending'::public.companion_status, 'active'::public.companion_status);
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
    target_companion_session_id,
    target_status,
    current_precision,
    resolved_dedupe_key,
    jsonb_build_object('source', 'manual')
  )
  on conflict (circle_id, subject_profile_id, dedupe_key)
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

create or replace function public.list_circle_check_ins(
  target_circle_id uuid,
  event_limit int default 20
)
returns table (
  id uuid,
  circle_id uuid,
  actor_profile_id uuid,
  subject_profile_id uuid,
  display_name text,
  status text,
  sharing_precision public.sharing_precision,
  companion_session_id uuid,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    e.id,
    e.circle_id,
    e.actor_profile_id,
    e.subject_profile_id,
    p.display_name,
    e.status,
    e.sharing_precision,
    e.companion_session_id,
    e.created_at
  from public.check_in_events e
  join public.profiles p on p.id = e.subject_profile_id
  where e.circle_id = target_circle_id
    and e.expires_at > now()
    and public.is_circle_member(target_circle_id, auth.uid())
    and (
      e.subject_profile_id = auth.uid()
      or public.can_view_profile_location(e.subject_profile_id, auth.uid())
    )
  order by e.created_at desc
  limit least(greatest(event_limit, 1), 50);
$$;

grant execute on function public.perform_check_in(uuid, uuid, text, text) to authenticated;
grant execute on function public.list_circle_check_ins(uuid, int) to authenticated;

comment on table public.check_in_events is
  'Short circle-visible reassurance events. Does not store raw or shared coordinates.';

comment on function public.perform_check_in(uuid, uuid, text, text) is
  'Creates a coordinate-free check-in event and ends the caller subject companion session when provided.';

comment on function public.list_circle_check_ins(uuid, int) is
  'Lists recent coordinate-free check-in events for authorized members of a circle.';
