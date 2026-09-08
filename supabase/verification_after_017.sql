-- Read-only verification for migration 017 (meetups).
select
  to_regclass('public.meetups') is not null as meetups_table_installed,
  to_regclass('public.meetup_attendees') is not null
    as meetup_attendees_table_installed,

  (select relrowsecurity from pg_class where oid = 'public.meetups'::regclass)
    as meetups_rls_enabled,
  (select relrowsecurity
     from pg_class where oid = 'public.meetup_attendees'::regclass)
    as meetup_attendees_rls_enabled,

  -- 클라이언트 직접 insert 는 막혀 있어야 한다. 참석자 행과 멤버십 검사가
  -- RPC 안에서 원자적으로 일어나야 하기 때문이다.
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'meetups'
      and policyname = 'meetups_no_client_insert'
  ) as meetups_client_insert_blocked,
  not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'meetups'
      and cmd = 'INSERT' and policyname <> 'meetups_no_client_insert'
  ) as meetups_no_other_insert_policy,

  to_regprocedure('public.is_meetup_over(timestamptz, int, timestamptz)')
    is not null as meetup_expiry_predicate_installed,
  to_regprocedure(
    'public.create_meetup(uuid, text, double precision, double precision, timestamptz, text, int, uuid[])'
  ) is not null as create_meetup_rpc_installed,
  to_regprocedure('public.respond_to_meetup(uuid, text)') is not null
    as respond_to_meetup_rpc_installed,
  to_regprocedure('public.end_meetup(uuid)') is not null
    as end_meetup_rpc_installed,
  to_regprocedure('public.list_active_meetups(uuid)') is not null
    as list_active_meetups_rpc_installed,

  has_function_privilege(
    'authenticated', 'public.list_active_meetups(uuid)', 'EXECUTE'
  ) as list_active_meetups_granted,

  -- 만료는 읽을 때 판정한다. 목록 RPC 가 그 술어를 실제로 쓰는지 본다.
  -- 안 쓰면 끝난 약속이 계속 지도에 남는다.
  pg_get_functiondef('public.list_active_meetups(uuid)'::regprocedure)
    like '%is_meetup_over%' as list_filters_expired_meetups,

  -- 만든 사람만 끝낼 수 있어야 한다.
  pg_get_functiondef('public.end_meetup(uuid)'::regprocedure)
    like '%created_by = current_user_id%' as end_meetup_creator_scoped,

  -- 지난 시각으로 만들면 만들자마자 만료된다. 사고에 가깝다.
  pg_get_functiondef(
    'public.create_meetup(uuid, text, double precision, double precision, timestamptz, text, int, uuid[])'::regprocedure
  ) like '%meetup_in_the_past%' as create_meetup_rejects_past;
