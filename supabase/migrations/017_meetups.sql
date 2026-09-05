-- 017: 약속 — 집결 장소와 시각, 그리고 스스로 끝나는 성질.
--
-- 여행·친구 사용자가 이 카테고리에서 가장 불안해하는 것은 "끝났는데도 계속
-- 공유되고 있는 것"이다. 그래서 약속은 사람이 끄는 물건이 아니라 시각이 지나면
-- 스스로 사라지는 물건으로 만든다. 끄는 걸 잊어도 꺼진다.
--
-- 만료를 워커로 처리하지 않는다. 배경 작업이 밀리거나 죽으면 "꺼졌어야 할
-- 공유가 살아 있는" 상태가 되는데, 그게 정확히 막으려던 상황이다. 대신 만료를
-- 읽을 때 판정한다. 워커가 없어도 시각이 지나면 아무에게도 보이지 않는다.
-- 정리는 나중에 배치로 하면 되고, 그건 늦어도 안전하다.

create table public.meetups (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete cascade,
  created_by uuid not null references public.profiles (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 80),
  place_name text,
  place_lat double precision not null check (place_lat between -90 and 90),
  place_lng double precision not null check (place_lng between -180 and 180),
  meet_at timestamptz not null,
  -- 약속 시각이 지나도 곧바로 사라지면 늦는 사람이 길을 잃는다. 유예를 둔다.
  grace_minutes int not null default 30 check (grace_minutes between 0 and 240),
  ended_at timestamptz,
  end_reason text check (end_reason in ('creator_ended', 'expired')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index meetups_circle_meet_at_idx
  on public.meetups (circle_id, meet_at desc);

create table public.meetup_attendees (
  meetup_id uuid not null references public.meetups (id) on delete cascade,
  profile_id uuid not null references public.profiles (id) on delete cascade,
  response text not null default 'invited'
    check (response in ('invited', 'going', 'maybe', 'declined')),
  responded_at timestamptz,
  primary key (meetup_id, profile_id)
);

alter table public.meetups enable row level security;
alter table public.meetup_attendees enable row level security;

-- 서클 멤버는 읽을 수 있다. 쓰기는 RPC 로만 — place_alerts 와 같은 규칙이다.
create policy "meetups_select_circle_members" on public.meetups
for select using (public.is_circle_member(circle_id, auth.uid()));

create policy "meetups_no_client_insert" on public.meetups
for insert with check (false);

comment on policy "meetups_no_client_insert" on public.meetups is
  'Clients create meetups through create_meetup so attendee rows and membership checks happen atomically.';

create policy "meetup_attendees_select_via_meetup" on public.meetup_attendees
for select using (
  exists (
    select 1 from public.meetups m
    where m.id = meetup_id
      and public.is_circle_member(m.circle_id, auth.uid())
  )
);

create policy "meetup_attendees_no_client_insert" on public.meetup_attendees
for insert with check (false);

comment on table public.meetups is
  'A rendezvous point and time for a circle. Expires on its own; no worker required.';

-- 끝났는지 여부는 한 곳에서만 판정한다. 클라이언트와 여러 RPC 가 각자 계산하면
-- 곧 서로 다른 답을 낸다.
create or replace function public.is_meetup_over(
  meet_at timestamptz,
  grace_minutes int,
  ended_at timestamptz
)
returns boolean
language sql
immutable
as $$
  select ended_at is not null
      or now() > meet_at + make_interval(mins => grace_minutes);
$$;

comment on function public.is_meetup_over(timestamptz, int, timestamptz) is
  'Single source of truth for meetup expiry. Read-time predicate so a stalled worker cannot leave sharing on.';

create or replace function public.create_meetup(
  target_circle_id uuid,
  meetup_name text,
  meetup_place_lat double precision,
  meetup_place_lng double precision,
  meetup_meet_at timestamptz,
  meetup_place_name text default null,
  meetup_grace_minutes int default 30,
  attendee_profile_ids uuid[] default null
)
returns table (
  id uuid,
  circle_id uuid,
  created_by uuid,
  name text,
  place_name text,
  place_lat double precision,
  place_lng double precision,
  meet_at timestamptz,
  grace_minutes int,
  ended_at timestamptz,
  created_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  saved public.meetups%rowtype;
  invited uuid[];
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_circle_member(target_circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  -- 지난 시각으로 약속을 만들면 만들자마자 만료된다. 사고에 가깝다.
  if meetup_meet_at < now() - interval '5 minutes' then
    raise exception 'meetup_in_the_past';
  end if;

  insert into public.meetups (
    circle_id, created_by, name, place_name,
    place_lat, place_lng, meet_at, grace_minutes
  )
  values (
    target_circle_id, current_user_id, trim(meetup_name), meetup_place_name,
    meetup_place_lat, meetup_place_lng, meetup_meet_at, meetup_grace_minutes
  )
  returning * into saved;

  -- 대상을 지정하지 않으면 서클 전체를 부른다.
  invited := coalesce(attendee_profile_ids, array(
    select cm.profile_id from public.circle_members cm
    where cm.circle_id = target_circle_id
  ));

  insert into public.meetup_attendees (meetup_id, profile_id, response, responded_at)
  select
    saved.id,
    p,
    case when p = current_user_id then 'going' else 'invited' end,
    case when p = current_user_id then now() else null end
  from unnest(invited) as p
  where public.is_circle_member(target_circle_id, p)
  on conflict do nothing;

  return query
  select saved.id, saved.circle_id, saved.created_by, saved.name,
         saved.place_name, saved.place_lat, saved.place_lng,
         saved.meet_at, saved.grace_minutes, saved.ended_at, saved.created_at;
end;
$$;

create or replace function public.respond_to_meetup(
  target_meetup_id uuid,
  attendee_response text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  target public.meetups%rowtype;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if attendee_response not in ('going', 'maybe', 'declined') then
    raise exception 'invalid_meetup_response';
  end if;

  select * into target from public.meetups where id = target_meetup_id;
  if target.id is null then
    raise exception 'meetup_not_found';
  end if;

  if not public.is_circle_member(target.circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  if public.is_meetup_over(target.meet_at, target.grace_minutes, target.ended_at) then
    raise exception 'meetup_already_over';
  end if;

  insert into public.meetup_attendees (meetup_id, profile_id, response, responded_at)
  values (target_meetup_id, current_user_id, attendee_response, now())
  on conflict (meetup_id, profile_id)
  do update set response = excluded.response, responded_at = excluded.responded_at;
end;
$$;

create or replace function public.end_meetup(target_meetup_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- 만든 사람만 끝낼 수 있다. 아무나 끄면 다른 사람의 합류가 끊긴다.
  update public.meetups
    set ended_at = coalesce(ended_at, now()),
        end_reason = coalesce(end_reason, 'creator_ended'),
        updated_at = now()
  where id = target_meetup_id
    and created_by = current_user_id;

  if not found then
    raise exception 'meetup_not_found_or_not_creator';
  end if;
end;
$$;

-- 끝나지 않은 약속만 돌려준다. 만료 판정이 여기 있으므로 클라이언트가 시계를
-- 따로 볼 필요가 없다.
create or replace function public.list_active_meetups(target_circle_id uuid)
returns table (
  id uuid,
  circle_id uuid,
  created_by uuid,
  name text,
  place_name text,
  place_lat double precision,
  place_lng double precision,
  meet_at timestamptz,
  grace_minutes int,
  my_response text,
  going_count int,
  attendee_count int
)
language sql
security definer
set search_path = public
as $$
  select
    m.id, m.circle_id, m.created_by, m.name, m.place_name,
    m.place_lat, m.place_lng, m.meet_at, m.grace_minutes,
    coalesce(mine.response, 'invited'),
    (select count(*)::int from public.meetup_attendees a
      where a.meetup_id = m.id and a.response = 'going'),
    (select count(*)::int from public.meetup_attendees a where a.meetup_id = m.id)
  from public.meetups m
  left join public.meetup_attendees mine
    on mine.meetup_id = m.id and mine.profile_id = auth.uid()
  where m.circle_id = target_circle_id
    and public.is_circle_member(target_circle_id, auth.uid())
    and not public.is_meetup_over(m.meet_at, m.grace_minutes, m.ended_at)
  order by m.meet_at asc;
$$;

grant execute on function public.is_meetup_over(timestamptz, int, timestamptz) to authenticated;
grant execute on function public.create_meetup(uuid, text, double precision, double precision, timestamptz, text, int, uuid[]) to authenticated;
grant execute on function public.respond_to_meetup(uuid, text) to authenticated;
grant execute on function public.end_meetup(uuid) to authenticated;
grant execute on function public.list_active_meetups(uuid) to authenticated;
