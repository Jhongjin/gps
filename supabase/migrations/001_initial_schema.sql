create extension if not exists "pgcrypto";

create type public.circle_role as enum ('owner', 'admin', 'member', 'guardian', 'child');
create type public.sharing_precision as enum ('precise', 'balanced', 'area', 'hidden', 'sos_only');
create type public.location_source as enum ('gps', 'network', 'significant_change', 'geofence', 'sos', 'unknown');
create type public.companion_status as enum ('pending', 'active', 'ended', 'expired', 'cancelled');
create type public.invitation_status as enum ('pending', 'accepted', 'revoked', 'expired');
create type public.request_status as enum ('pending', 'processing', 'completed', 'failed', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  avatar_url text,
  birth_year int,
  is_minor boolean not null default false,
  guardian_profile_id uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.circles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  circle_type text not null default 'family',
  created_by uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.circle_members (
  circle_id uuid not null references public.circles (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  role public.circle_role not null default 'member',
  can_view_location boolean not null default true,
  joined_at timestamptz not null default now(),
  removed_at timestamptz,
  primary key (circle_id, profile_id)
);

create table public.circle_invitations (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  invited_by uuid not null references public.profiles (id) on delete cascade,
  invite_code_hint text,
  invite_token_hash text not null,
  max_uses int not null default 1,
  use_count int not null default 0,
  status public.invitation_status not null default 'pending',
  expires_at timestamptz not null,
  accepted_by uuid references public.profiles (id),
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  constraint circle_invitations_use_count_valid check (
    max_uses > 0 and use_count >= 0 and use_count <= max_uses
  )
);

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android')),
  push_token text,
  app_version text,
  last_seen_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.sharing_policies (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  precision public.sharing_precision not null default 'balanced',
  enabled boolean not null default true,
  paused_until timestamptz,
  expires_at timestamptz,
  consent_version text not null default '2026-05-30',
  updated_at timestamptz not null default now(),
  unique (circle_id, profile_id)
);

create table public.companion_sessions (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  subject_profile_id uuid not null references public.profiles (id) on delete cascade,
  started_by uuid not null references public.profiles (id) on delete cascade,
  status public.companion_status not null default 'pending',
  precision public.sharing_precision not null default 'balanced',
  started_at timestamptz,
  expires_at timestamptz not null,
  ended_at timestamptz,
  end_reason text,
  created_at timestamptz not null default now()
);

create table public.latest_locations (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  source public.location_source not null default 'unknown',
  raw_lat double precision,
  raw_lng double precision,
  shared_lat double precision,
  shared_lng double precision,
  accuracy_m double precision,
  speed_mps double precision,
  heading_deg double precision,
  battery_percent int,
  sharing_precision public.sharing_precision not null,
  recorded_at timestamptz not null,
  updated_at timestamptz not null default now(),
  constraint latest_locations_no_hidden_shared_coords check (
    sharing_precision <> 'hidden' or (shared_lat is null and shared_lng is null)
  )
);

create table public.location_history (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  companion_session_id uuid references public.companion_sessions (id) on delete set null,
  source public.location_source not null default 'unknown',
  raw_lat double precision,
  raw_lng double precision,
  shared_lat double precision,
  shared_lng double precision,
  accuracy_m double precision,
  sharing_precision public.sharing_precision not null,
  recorded_at timestamptz not null,
  expires_at timestamptz not null default (now() + interval '30 days')
);

create index location_history_profile_recorded_idx on public.location_history (profile_id, recorded_at desc);
create index location_history_expires_idx on public.location_history (expires_at);

create table public.place_alerts (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  created_by uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  center_lat double precision not null,
  center_lng double precision not null,
  radius_m int not null check (radius_m between 50 and 5000),
  notify_on_arrival boolean not null default true,
  notify_on_departure boolean not null default true,
  notify_on_late boolean not null default false,
  notify_on_long_stay boolean not null default false,
  quiet_hours jsonb not null default '{}'::jsonb,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.place_alert_targets (
  place_alert_id uuid not null references public.place_alerts (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  primary key (place_alert_id, profile_id)
);

create table public.viewer_logs (
  id uuid primary key default gen_random_uuid(),
  viewed_profile_id uuid not null references public.profiles (id) on delete cascade,
  viewer_profile_id uuid not null references public.profiles (id) on delete cascade,
  circle_id uuid references public.circles (id) on delete set null,
  precision public.sharing_precision not null,
  viewed_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '30 days')
);

create index viewer_logs_viewed_profile_idx on public.viewer_logs (viewed_profile_id, viewed_at desc);

create table public.ad_preferences (
  profile_id uuid primary key references public.profiles (id) on delete cascade,
  personalized_ads_enabled boolean not null default false,
  sensitive_categories_blocked boolean not null default true,
  precise_location_ads_enabled boolean not null default false,
  updated_at timestamptz not null default now(),
  constraint no_precise_location_ads check (precise_location_ads_enabled = false)
);

create table public.data_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles (id) on delete cascade,
  request_type text not null check (request_type in ('export', 'delete_history', 'delete_account')),
  status public.request_status not null default 'pending',
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  result_url text
);

create or replace function public.is_circle_member(target_circle_id uuid, target_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.circle_members cm
    where cm.circle_id = target_circle_id
      and cm.profile_id = target_profile_id
      and cm.removed_at is null
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
  );
$$;

alter table public.profiles enable row level security;
alter table public.circles enable row level security;
alter table public.circle_members enable row level security;
alter table public.circle_invitations enable row level security;
alter table public.devices enable row level security;
alter table public.sharing_policies enable row level security;
alter table public.companion_sessions enable row level security;
alter table public.latest_locations enable row level security;
alter table public.location_history enable row level security;
alter table public.place_alerts enable row level security;
alter table public.place_alert_targets enable row level security;
alter table public.viewer_logs enable row level security;
alter table public.ad_preferences enable row level security;
alter table public.data_requests enable row level security;

create policy "profiles_select_self_or_circle" on public.profiles
for select using (
  id = auth.uid()
  or exists (
    select 1
    from public.circle_members mine
    join public.circle_members theirs on theirs.circle_id = mine.circle_id
    where mine.profile_id = auth.uid()
      and theirs.profile_id = profiles.id
      and mine.removed_at is null
      and theirs.removed_at is null
  )
);

create policy "profiles_update_self" on public.profiles
for update using (id = auth.uid()) with check (id = auth.uid());

create policy "circles_select_members" on public.circles
for select using (public.is_circle_member(id, auth.uid()));

create policy "circles_insert_creator" on public.circles
for insert with check (created_by = auth.uid());

create policy "circle_members_select_members" on public.circle_members
for select using (public.is_circle_member(circle_id, auth.uid()));

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

create policy "devices_owner_all" on public.devices
for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "sharing_policies_select_circle_members" on public.sharing_policies
for select using (public.is_circle_member(circle_id, auth.uid()));

create policy "sharing_policies_owner_update" on public.sharing_policies
for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "companion_select_circle_members" on public.companion_sessions
for select using (public.is_circle_member(circle_id, auth.uid()));

create policy "companion_insert_members" on public.companion_sessions
for insert with check (
  started_by = auth.uid()
  and public.is_circle_member(circle_id, auth.uid())
);

create policy "companion_update_subject_or_starter" on public.companion_sessions
for update using (subject_profile_id = auth.uid() or started_by = auth.uid())
with check (subject_profile_id = auth.uid() or started_by = auth.uid());

create policy "latest_locations_select_authorized" on public.latest_locations
for select using (
  profile_id = auth.uid()
  or public.can_view_profile_location(profile_id, auth.uid())
);

create policy "latest_locations_owner_write" on public.latest_locations
for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "location_history_select_owner" on public.location_history
for select using (profile_id = auth.uid());

create policy "location_history_owner_insert" on public.location_history
for insert with check (profile_id = auth.uid());

create policy "place_alerts_select_circle_members" on public.place_alerts
for select using (public.is_circle_member(circle_id, auth.uid()));

create policy "place_alerts_insert_circle_members" on public.place_alerts
for insert with check (created_by = auth.uid() and public.is_circle_member(circle_id, auth.uid()));

create policy "place_targets_select_via_alert" on public.place_alert_targets
for select using (
  exists (
    select 1 from public.place_alerts pa
    where pa.id = place_alert_id
      and public.is_circle_member(pa.circle_id, auth.uid())
  )
);

create policy "viewer_logs_select_viewed_or_viewer" on public.viewer_logs
for select using (viewed_profile_id = auth.uid() or viewer_profile_id = auth.uid());

create policy "viewer_logs_insert_viewer" on public.viewer_logs
for insert with check (viewer_profile_id = auth.uid());

create policy "ad_preferences_owner_all" on public.ad_preferences
for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "data_requests_owner_all" on public.data_requests
for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());
