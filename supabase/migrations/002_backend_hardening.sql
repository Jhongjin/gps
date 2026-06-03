do $$
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'circle_invitations'
      and column_name = 'invite_code'
  ) and not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'circle_invitations'
      and column_name = 'invite_code_hint'
  ) then
    alter table public.circle_invitations rename column invite_code to invite_code_hint;
  end if;
end $$;

alter table public.circle_invitations
  add column if not exists invite_code_hint text,
  add column if not exists invite_token_hash text,
  add column if not exists max_uses int not null default 1,
  add column if not exists use_count int not null default 0;

alter table public.circle_invitations
  alter column invite_code_hint drop not null;

create unique index if not exists circle_invitations_token_hash_idx
  on public.circle_invitations (invite_token_hash)
  where invite_token_hash is not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'circle_invitations_use_count_valid'
      and conrelid = 'public.circle_invitations'::regclass
  ) then
    alter table public.circle_invitations
      add constraint circle_invitations_use_count_valid check (
        max_uses > 0 and use_count >= 0 and use_count <= max_uses
      );
  end if;
end $$;

alter table public.companion_sessions
  add column requires_mutual_consent boolean not null default true;

create table public.companion_session_members (
  session_id uuid not null references public.companion_sessions (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  consented_at timestamptz,
  revoked_at timestamptz,
  can_view boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (session_id, profile_id)
);

create table public.consent_events (
  id uuid primary key default gen_random_uuid(),
  actor_profile_id uuid not null references public.profiles (id) on delete cascade,
  subject_profile_id uuid references public.profiles (id) on delete cascade,
  circle_id uuid references public.circles (id) on delete cascade,
  session_id uuid references public.companion_sessions (id) on delete set null,
  event_type text not null check (
    event_type in (
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
  ),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.place_alert_events (
  id uuid primary key default gen_random_uuid(),
  place_alert_id uuid not null references public.place_alerts (id) on delete cascade,
  subject_profile_id uuid not null references public.profiles (id) on delete cascade,
  event_type text not null check (event_type in ('arrived', 'departed', 'late', 'long_stay', 'delivery_failed')),
  dedupe_key text not null,
  occurred_at timestamptz not null default now(),
  delivered_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  unique (place_alert_id, subject_profile_id, dedupe_key)
);

alter table public.latest_locations
  add column device_id uuid references public.devices (id) on delete set null;

alter table public.location_history
  add column device_id uuid references public.devices (id) on delete set null;

create index latest_locations_device_idx on public.latest_locations (device_id);
create index location_history_device_recorded_idx on public.location_history (device_id, recorded_at desc);

create or replace function public.prevent_companion_session_identity_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.circle_id <> old.circle_id
    or new.subject_profile_id <> old.subject_profile_id
    or new.started_by <> old.started_by then
    raise exception 'companion_session_identity_immutable';
  end if;

  return new;
end;
$$;

drop trigger if exists companion_sessions_identity_immutable on public.companion_sessions;

create trigger companion_sessions_identity_immutable
before update on public.companion_sessions
for each row execute function public.prevent_companion_session_identity_change();

create or replace function public.is_active_companion_session_member(target_session_id uuid, target_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.companion_sessions cs
    join public.companion_session_members csm on csm.session_id = cs.id
    where cs.id = target_session_id
      and csm.profile_id = target_profile_id
      and cs.status = 'active'
      and cs.expires_at > now()
      and csm.consented_at is not null
      and csm.revoked_at is null
      and csm.can_view
  );
$$;

create or replace function public.can_view_profile_location(target_profile_id uuid, viewer_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.circle_members subject_cm
    join public.circle_members viewer_cm on viewer_cm.circle_id = subject_cm.circle_id
    join public.sharing_policies sp on sp.circle_id = subject_cm.circle_id and sp.profile_id = subject_cm.profile_id
    where subject_cm.profile_id = target_profile_id
      and viewer_cm.profile_id = viewer_profile_id
      and subject_cm.removed_at is null
      and viewer_cm.removed_at is null
      and viewer_cm.can_view_location
      and sp.enabled
      and sp.precision <> 'hidden'
      and (sp.paused_until is null or sp.paused_until < now())
      and (sp.expires_at is null or sp.expires_at > now())
  )
  or exists (
    select 1
    from public.companion_sessions cs
    join public.companion_session_members subject_member on subject_member.session_id = cs.id
    join public.companion_session_members viewer_member on viewer_member.session_id = cs.id
    where cs.subject_profile_id = target_profile_id
      and subject_member.profile_id = target_profile_id
      and viewer_member.profile_id = viewer_profile_id
      and cs.status = 'active'
      and cs.expires_at > now()
      and subject_member.consented_at is not null
      and subject_member.revoked_at is null
      and viewer_member.consented_at is not null
      and viewer_member.revoked_at is null
      and viewer_member.can_view
  );
$$;

alter table public.companion_session_members enable row level security;
alter table public.consent_events enable row level security;
alter table public.place_alert_events enable row level security;

drop policy if exists "latest_locations_owner_write" on public.latest_locations;
drop policy if exists "location_history_owner_insert" on public.location_history;
drop policy if exists "viewer_logs_insert_viewer" on public.viewer_logs;
drop policy if exists "companion_insert_members" on public.companion_sessions;
drop policy if exists "companion_update_subject_or_starter" on public.companion_sessions;
drop policy if exists "circle_invitations_select_circle_members" on public.circle_invitations;
drop policy if exists "circle_invitations_insert_circle_members" on public.circle_invitations;
drop policy if exists "circle_invitations_update_inviter" on public.circle_invitations;

create policy "circle_invitations_select_circle_members" on public.circle_invitations
for select using (public.is_circle_member(circle_id, auth.uid()));

create policy "circle_invitations_insert_circle_members" on public.circle_invitations
for insert with check (
  invited_by = auth.uid()
  and invite_token_hash is not null
  and public.is_circle_member(circle_id, auth.uid())
);

create policy "circle_invitations_update_inviter" on public.circle_invitations
for update using (
  invited_by = auth.uid()
  and status = 'pending'
) with check (
  invited_by = auth.uid()
  and public.is_circle_member(circle_id, auth.uid())
);

create policy "companion_insert_circle_subject_members" on public.companion_sessions
for insert with check (
  started_by = auth.uid()
  and public.is_circle_member(circle_id, auth.uid())
  and public.is_circle_member(circle_id, subject_profile_id)
);

create policy "companion_update_subject_or_starter" on public.companion_sessions
for update using (
  (subject_profile_id = auth.uid() or started_by = auth.uid())
  and status in ('pending', 'active')
) with check (
  (subject_profile_id = auth.uid() or started_by = auth.uid())
  and public.is_circle_member(circle_id, subject_profile_id)
);

create policy "latest_locations_owner_registered_device_insert" on public.latest_locations
for insert with check (
  profile_id = auth.uid()
  and exists (
    select 1 from public.devices d
    where d.id = latest_locations.device_id
      and d.profile_id = auth.uid()
  )
);

create policy "latest_locations_owner_registered_device_update" on public.latest_locations
for update using (
  profile_id = auth.uid()
  and exists (
    select 1 from public.devices d
    where d.id = latest_locations.device_id
      and d.profile_id = auth.uid()
  )
) with check (
  profile_id = auth.uid()
  and exists (
    select 1 from public.devices d
    where d.id = latest_locations.device_id
      and d.profile_id = auth.uid()
  )
);

create policy "location_history_owner_registered_device_insert" on public.location_history
for insert with check (
  profile_id = auth.uid()
  and exists (
    select 1 from public.devices d
    where d.id = location_history.device_id
      and d.profile_id = auth.uid()
  )
);

create policy "session_members_select_participants" on public.companion_session_members
for select using (public.is_active_companion_session_member(session_id, auth.uid()));

create policy "session_members_insert_circle_members" on public.companion_session_members
for insert with check (
  profile_id = auth.uid()
  and
  exists (
    select 1
    from public.companion_sessions cs
    where cs.id = session_id
      and public.is_circle_member(cs.circle_id, auth.uid())
      and public.is_circle_member(cs.circle_id, profile_id)
  )
);

create policy "session_members_update_self" on public.companion_session_members
for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "consent_events_select_actor_or_subject" on public.consent_events
for select using (actor_profile_id = auth.uid() or subject_profile_id = auth.uid());

create policy "consent_events_insert_actor" on public.consent_events
for insert with check (actor_profile_id = auth.uid());

create policy "place_alert_events_select_circle_members" on public.place_alert_events
for select using (
  exists (
    select 1
    from public.place_alerts pa
    where pa.id = place_alert_id
      and public.is_circle_member(pa.circle_id, auth.uid())
  )
);

create policy "viewer_logs_no_client_insert" on public.viewer_logs
for insert with check (false);

comment on table public.location_history is 'Do not enable broad realtime on this table. Use latest_locations or private session topics for live map state.';
comment on table public.viewer_logs is 'Append-only server-side audit log. Client inserts are blocked by RLS.';
comment on column public.circle_invitations.invite_code_hint is 'Optional non-secret short display hint. Do not store raw invitation URLs or bearer tokens.';
comment on column public.circle_invitations.invite_token_hash is 'Store only a one-way hash of invitation token. Do not store raw invite links.';
