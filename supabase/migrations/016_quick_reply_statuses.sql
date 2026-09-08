-- 016: 정형 반응 3종을 check_in_events 에 추가한다.
--
-- 앱 안에서 한 번 눌러 보낼 수 있는 짧은 말이 없어서, 가족의 위치가 52분째
-- 갱신되지 않아도 앱 안에서 할 수 있는 일이 없었다. 그래서 사람들이 메신저로
-- 나가고, 나간 뒤에는 돌아오지 않는다.
--
-- 새 테이블을 만들지 않는다. check_in_events 가 이미 '좌표를 담지 않는 짧은
-- 서클 공개 이벤트'이고 RLS·중복 제거·조회 RPC·기록 화면이 붙어 있다. 정형
-- 반응은 정확히 같은 성격의 데이터다.
--
--   safe_arrived  도착했어  (이미 있음)
--   on_the_way    가는 중
--   im_ok         괜찮아
--   call_me       전화해줘
--
-- needs_check 와 signal_weak 는 사용자가 누르는 값이 아니라 시스템이 판단하는
-- 상태이므로 그대로 둔다.
--
-- 아래 함수 본문은 009 원본을 그대로 옮기고 세 곳만 바꿨다. security definer
-- 함수를 기억에 의존해 다시 쓰면 가드가 조용히 사라진다.

alter table public.check_in_events
  drop constraint if exists check_in_events_status_check;

alter table public.check_in_events
  add constraint check_in_events_status_check
  check (
    status in (
      'safe_arrived', 'needs_check', 'signal_weak',
      'on_the_way', 'im_ok', 'call_me'
    )
  );

comment on table public.check_in_events is
  'Short circle-visible reassurance events and quick replies. Does not store raw or shared coordinates.';

-- 아래 함수 본문은 **010** 을 바탕으로 한다. 처음에는 009 를 베꼈는데, 그러면
-- 010 이 넣은 두 가지가 사라진다: 세션 종료 전 호출자가 그 세션의 당사자인지
-- 확인하는 검사(companion_session_subject_required)와, 반환 칼럼 `id` 와 겹쳐
-- PL/pgSQL 이 "column reference is ambiguous" 로 죽던 UPDATE 의 칼럼 한정.
-- 둘 다 tools/check_migrations_local.py 가 부정 테스트를 돌리기 전까지 보이지
-- 않았다. 010 위에 얹는 변경은 셋뿐이다: 상태 목록, 도착 확인일 때만 세션 종료,
-- 디듀프 키에 상태 포함.
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
  linked_companion_session_id uuid;
  resolved_dedupe_key text;
  saved_event public.check_in_events%rowtype;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if not public.is_circle_member(target_circle_id, current_user_id) then
    raise exception 'circle_membership_required';
  end if;

  if target_status not in
    ('safe_arrived', 'needs_check', 'signal_weak', 'on_the_way', 'im_ok', 'call_me')
  then
    raise exception 'invalid_check_in_status';
  end if;

  -- 세션을 끝내는 것은 도착 확인일 때만이다. '가는 중'이나 '전화해줘'로 세션이
  -- 끝나면 마침 위치 공유가 필요한 순간에 공유가 꺼진다.
  if target_companion_session_id is not null and target_status <> 'safe_arrived' then
    raise exception 'session_end_requires_arrival';
  end if;

  select sp.precision
    into current_precision
  from public.sharing_policies sp
  where sp.circle_id = target_circle_id
    and sp.profile_id = current_user_id;

  current_precision := coalesce(current_precision, 'balanced'::public.sharing_precision);

  if target_companion_session_id is not null then
    select cs.id
      into linked_companion_session_id
    from public.companion_sessions cs
    where cs.id = target_companion_session_id
      and cs.circle_id = target_circle_id
      and cs.subject_profile_id = current_user_id
      and cs.status in ('pending'::public.companion_status, 'active'::public.companion_status)
      and cs.expires_at > now();

    if linked_companion_session_id is null then
      raise exception 'companion_session_subject_required';
    end if;

    update public.companion_sessions
      set status = 'ended'::public.companion_status,
          ended_at = coalesce(ended_at, now()),
          end_reason = 'manual_check_in'
    where public.companion_sessions.id = linked_companion_session_id;
  end if;

  resolved_dedupe_key := coalesce(
    nullif(client_dedupe_key, ''),
    'manual:' || target_circle_id::text || ':' || current_user_id::text || ':' ||
      target_status || ':' ||
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
    linked_companion_session_id,
    target_status,
    current_precision,
    resolved_dedupe_key,
    jsonb_build_object('source', 'manual')
  )
  on conflict on constraint check_in_events_circle_id_subject_profile_id_dedupe_key_key
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

grant execute on function public.perform_check_in(uuid, uuid, text, text) to authenticated;

comment on function public.perform_check_in(uuid, uuid, text, text) is
  'Creates a coordinate-free check-in or quick reply. Ends the caller subject companion session only for safe_arrived, and only when that session belongs to the caller and is still pending or active.';
