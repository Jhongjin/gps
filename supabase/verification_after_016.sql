-- Read-only verification for migration 016 (quick reply statuses).
select
  -- 정형 반응 세 값이 제약에 들어왔는지.
  (select pg_get_constraintdef(oid)
     from pg_constraint
    where conrelid = 'public.check_in_events'::regclass
      and conname = 'check_in_events_status_check')
    like '%on_the_way%' as on_the_way_allowed,
  (select pg_get_constraintdef(oid)
     from pg_constraint
    where conrelid = 'public.check_in_events'::regclass
      and conname = 'check_in_events_status_check')
    like '%im_ok%' as im_ok_allowed,
  (select pg_get_constraintdef(oid)
     from pg_constraint
    where conrelid = 'public.check_in_events'::regclass
      and conname = 'check_in_events_status_check')
    like '%call_me%' as call_me_allowed,

  -- 세션을 끝내는 것은 도착 확인뿐이어야 한다. 이 가드가 없으면 '가는 중'을
  -- 보낸 순간 마침 필요한 위치 공유가 꺼진다.
  pg_get_functiondef(
    'public.perform_check_in(uuid, uuid, text, text)'::regprocedure
  ) like '%session_end_requires_arrival%' as arrival_only_ends_session,

  -- 자동 중복제거 키에 상태가 들어갔는지. 없으면 같은 분에 보낸 다른 반응이
  -- 서로를 덮어쓴다.
  pg_get_functiondef(
    'public.perform_check_in(uuid, uuid, text, text)'::regprocedure
  ) like '%target_status ||%' as dedupe_key_includes_status,

  -- 009 에서 옮겨온 것들이 그대로 남아 있는지. 재작성 과정에서 가장 쉽게
  -- 사라지는 부분들이다.
  pg_get_functiondef(
    'public.perform_check_in(uuid, uuid, text, text)'::regprocedure
  ) like '%manual_check_in%' as end_reason_preserved,
  pg_get_functiondef(
    'public.perform_check_in(uuid, uuid, text, text)'::regprocedure
  ) like '%sharing_precision%' as sharing_precision_preserved,

  has_function_privilege(
    'authenticated', 'public.perform_check_in(uuid, uuid, text, text)', 'EXECUTE'
  ) as perform_check_in_granted;
