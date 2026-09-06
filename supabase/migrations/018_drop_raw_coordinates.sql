-- 원시 좌표 칸을 없앤다.
--
-- `latest_locations.raw_lat/raw_lng` 와 `location_history.raw_lat/raw_lng` 는
-- 001 부터 계속 기록됐지만, 이 스키마의 어떤 RPC·뷰·정책·트리거도 그 값을 읽지
-- 않는다. 008 의 함수 주석은 "Raw coordinates stay server-side" 라고 적혀
-- 있는데, 설계 의도는 원시 좌표가 **기기에** 남는 것이었다. 실제로는 정확한
-- 좌표가 아무도 읽지 않는 채로 30일씩 쌓이고 있었다.
--
-- 이건 취향 문제가 아니다. 사용자가 공유 정확도를 '동네만'이나 '숨김'으로
-- 두어도 정확한 좌표는 그대로 올라갔다. 화면이 약속한 것과 저장된 것이 달랐다.
-- 민감 장소 가림도 이 칸이 남아 있는 한 겉치레다 — 가려진 좌표 옆에 가려지지
-- 않은 좌표가 같은 행에 있었다.
--
-- **적용 순서.** 이 마이그레이션은 앱이 이 칸을 더 이상 보내지 않게 된 뒤에
-- 적용해야 한다. 순서가 뒤집히면 구버전 클라이언트의 insert 가 알 수 없는 칸
-- 오류로 실패하고, 그 결과는 위치 업로드 중단이다. 이 저장소에서는 Dart 와
-- Kotlin 업로드 경로에서 이미 제거했다.
--
-- **되돌릴 수 없다.** 칸과 함께 그 안의 값도 사라진다. 그것이 이 변경의
-- 목적이다.

alter table public.latest_locations drop column if exists raw_lat;
alter table public.latest_locations drop column if exists raw_lng;

alter table public.location_history drop column if exists raw_lat;
alter table public.location_history drop column if exists raw_lng;

comment on table public.latest_locations is
  'Latest shared coordinate per profile. Precise coordinates never leave the device; only the shared, precision-reduced and privacy-masked value is stored.';

comment on table public.location_history is
  'Bounded shared-coordinate history. Precise coordinates never leave the device; only the shared, precision-reduced and privacy-masked value is stored.';

comment on function public.get_circle_member_route_tail(uuid, uuid, int, timestamptz) is
  'Returns a bounded shared-coordinate route tail for one member in an authorized circle. Precise coordinates are never uploaded, so there is nothing coarser to withhold here.';
