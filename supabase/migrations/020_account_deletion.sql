-- 계정 삭제와 기록 삭제를 실제로 한다.
--
-- 안심 화면의 "기록 삭제"는 data_requests 에 행을 하나 넣었고, 그 행을 읽는 것은
-- 아무것도 없었다. 계정 삭제는 계약(DataRequestType.deleteAccount)에만 있고 화면에
-- 없었다. Google Play 와 App Store 는 둘 다 앱 안에서 계정을 삭제할 수 있어야 한다는
-- 조건을 건다 — 요청을 접수하는 것이 아니라 삭제가 일어나야 한다.
--
-- 두 함수 모두 auth.uid() 만 다룬다. 남의 것을 지우는 경로는 없다.

-- 1. 프로필을 가리키는 FK 중 cascade 가 아닌 둘. 이대로면 보호자로 지정된 사람이나
--    초대를 수락한 사람은 계정을 지울 수 없다(외래키 위반). 참조만 비운다.
alter table public.profiles
  drop constraint if exists profiles_guardian_profile_id_fkey,
  add constraint profiles_guardian_profile_id_fkey
    foreign key (guardian_profile_id) references public.profiles (id) on delete set null;

alter table public.circle_invitations
  drop constraint if exists circle_invitations_accepted_by_fkey,
  add constraint circle_invitations_accepted_by_fkey
    foreign key (accepted_by) references public.profiles (id) on delete set null;

-- 2. 내 위치 기록을 지운다. 지운 행 수를 돌려준다.
create or replace function public.delete_my_location_history()
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  removed int := 0;
  removed_latest int := 0;
begin
  if current_user_id is null then
    raise exception 'not_authenticated';
  end if;

  delete from public.location_history where profile_id = current_user_id;
  get diagnostics removed = row_count;

  delete from public.latest_locations where profile_id = current_user_id;
  get diagnostics removed_latest = row_count;

  -- 감사 기록. 요청 큐가 아니라 완료된 사실을 남긴다.
  insert into public.data_requests (profile_id, request_type, status, completed_at)
  values (current_user_id, 'delete_history', 'completed', now());

  return removed + removed_latest;
end;
$$;

grant execute on function public.delete_my_location_history() to authenticated;

comment on function public.delete_my_location_history() is
  'Deletes the caller''s location history and latest location immediately and records a completed data request.';

-- 3. 계정을 지운다. auth.users 행을 지우면 profiles 가 cascade 로 따라가고, 나머지
--    표는 profiles 를 cascade 로 따라간다. 이 함수가 auth.users 를 지울 수 있는 것은
--    security definer 로 소유자 권한을 쓰기 때문이다. 프로덕션에서 auth 스키마
--    권한이 막혀 실패하면, service role 을 쓰는 Edge Function 으로 옮긴다 —
--    클라이언트에 service role 을 주는 선택지는 없다.
create or replace function public.delete_my_account()
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

  -- 진행 중인 동행 세션을 먼저 끝낸다. cascade 로 사라지지만, 상대방이 받는
  -- 마지막 상태가 '끝남'이어야지 '사라짐'이면 안 된다.
  update public.companion_sessions
     set status = 'ended'::public.companion_status,
         ended_at = coalesce(companion_sessions.ended_at, now()),
         end_reason = 'account_deleted'
   where subject_profile_id = current_user_id
     and status in ('pending'::public.companion_status, 'active'::public.companion_status);

  delete from auth.users where id = current_user_id;
end;
$$;

grant execute on function public.delete_my_account() to authenticated;

comment on function public.delete_my_account() is
  'Deletes the calling user''s auth record; every profile-scoped row follows by cascade. No parameters: a user can only delete themselves.';
