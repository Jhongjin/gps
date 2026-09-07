-- 열람 기록을 본인이 읽을 수 있게 한다.
--
-- `record_viewer_log` 는 003 부터 있었지만 읽는 쪽이 없었다. 클라이언트도
-- 쓰지도 읽지도 않았다 — 로그인 화면은 "누가 내 위치를 봤는지 보여 준다"는
-- 배지를 달고 있었고, 멤버 시트에는 "오늘 이 위치를 본 사람" 줄이 있었는데,
-- 그 아래에 아무 데이터도 없었다. 약속만 있고 구현이 없는 상태였다.
--
-- 직접 select 로 풀지 않는 이유는 열람자 이름 때문이다. `viewer_logs` 는 RLS
-- 로 본인 것만 보이지만, 이름을 붙이려면 `profiles` 를 조인해야 하고 그건 다른
-- 정책의 문제가 된다. 여기서 security definer 로 필요한 만큼만 낸다.

create or replace function public.list_viewer_log(
  entry_limit int default 50,
  since_at timestamptz default null
)
returns table (
  id uuid,
  viewer_profile_id uuid,
  viewer_name text,
  circle_id uuid,
  -- `precision` 은 반환 테이블 칼럼 이름으로 쓸 수 없다(타입 키워드). 표에는
  -- 그 이름으로 있지만 여기서는 별칭을 준다.
  viewed_precision public.sharing_precision,
  viewed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    vl.id,
    vl.viewer_profile_id,
    coalesce(p.display_name, ''),
    vl.circle_id,
    vl.precision,
    vl.viewed_at
  from public.viewer_logs vl
  left join public.profiles p on p.id = vl.viewer_profile_id
  where vl.viewed_profile_id = auth.uid()
    -- 내가 내 위치를 본 것은 열람 기록이 아니다. 목록에 섞이면 남이 본
    -- 횟수를 읽을 수 없게 된다.
    and vl.viewer_profile_id <> auth.uid()
    and vl.viewed_at >= coalesce(since_at, now() - interval '30 days')
  order by vl.viewed_at desc
  limit least(greatest(coalesce(entry_limit, 50), 1), 200);
$$;

grant execute on function public.list_viewer_log(int, timestamptz) to authenticated;

comment on function public.list_viewer_log(int, timestamptz) is
  'Returns who viewed the calling user''s location. Scoped to auth.uid() as the viewed profile; a user can never read someone else''s viewer log.';
