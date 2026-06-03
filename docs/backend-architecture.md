# 백엔드 아키텍처 큐

Date: 2026-05-30

## 결정

MVP 백엔드는 Supabase Auth, Postgres, Row Level Security, Realtime을 기준선으로 둔다. 위치 수집량이 커지면 위치 ingest와 alert worker만 별도 서비스로 분리한다.

## 핵심 원칙

- 모든 public 테이블은 RLS를 켠다.
- 위치 조회 권한은 DB 함수 `can_view_profile_location`을 최종 관문으로 둔다.
- 원본 좌표와 공유 좌표를 분리한다.
- 광고 식별자, 광고 이벤트, 위치 원본 데이터는 같은 테이블에 두지 않는다.
- 초대 링크의 원문 토큰은 저장하지 않고 `invite_token_hash`만 저장한다.
- `viewer_logs`는 서버가 남기는 감사 로그이며 클라이언트 insert는 차단한다.

## 위치 데이터 흐름

1. 앱의 Swift/Kotlin 위치 브리지가 raw coordinate를 받는다.
2. 앱은 현재 공유 정책에 맞춰 shared coordinate를 계산한다.
3. 등록된 device id와 consent version을 함께 전송한다.
4. `latest_locations`는 사용자별 최신 상태만 upsert한다.
5. `location_history`는 보관 기간이 있는 append-only 기록으로 쌓는다.
6. 지도 실시간 화면은 `latest_locations` 또는 세션 전용 채널만 구독한다.
7. `location_history`에는 broad Realtime을 열지 않는다.

## 권한 모델

서클 기반 조회:

- 조회자와 대상자가 같은 active circle member여야 한다.
- 조회자의 `can_view_location`이 true여야 한다.
- 대상자의 `sharing_policies`가 enabled이고 hidden이 아니어야 한다.
- pause 또는 expires 상태면 조회할 수 없다.

동행 세션 조회:

- `companion_sessions.status = active`여야 한다.
- 세션 만료 시간이 지나지 않아야 한다.
- 대상자와 조회자 모두 `companion_session_members`에 있어야 한다.
- 양쪽 모두 `consented_at`이 있고 `revoked_at`이 없어야 한다.

## Realtime 전략

- `circle:{circleId}:locations`: 지도 화면에서 보는 최신 위치만 전송한다.
- `circle:{circleId}:events`: 장소 도착, 이탈, 배터리, 권한 문제 이벤트를 전송한다.
- `session:{sessionId}:route`: 동행 모드에서만 짧게 살아 있는 경로 채널이다.
- `user:{profileId}:private`: 초대, 데이터 요청, 보안 알림처럼 개인 대상 이벤트만 전송한다.

실시간 구독은 서버가 멤버십과 공유 정책을 다시 확인한 뒤 열어야 한다. 클라이언트에서 숨김 또는 일시 중지를 눌렀을 때는 Realtime 채널도 즉시 끊는다.

## 장소 알림

`place_alert_events`는 dedupe key를 강제한다. 같은 장소, 같은 대상, 같은 조건에서 반복 알림이 터지지 않게 앱과 서버 worker 모두 cooldown과 hysteresis를 적용한다.

권장 기본값:

- 도착/이탈 cooldown: 10분
- 늦음 알림 cooldown: 30분
- 경계 hysteresis: radius의 10% 또는 최소 30m
- 야간 quiet hours는 알림 전송 직전에 최종 확인

## 데이터 삭제와 보관

- 기본 위치 기록 보관: 30일
- 동행 route sample: 세션 종료 후 24시간 이내 요약 또는 삭제
- viewer log: 30일
- data request는 `data_requests`에 pending으로 기록하고 worker가 비동기로 처리
- 계정 삭제는 즉시 접근 차단 후 백그라운드에서 저장소, 캐시, 검색 인덱스까지 정리

## 서버 작업자

MVP에서 필요한 worker:

- location ingest 검증 및 rate limit
- place alert 판정과 push 발송
- viewer log 기록
- data export/delete request 처리
- expired location/history cleanup

Supabase Edge Function으로 시작할 수 있지만, 위치 트래픽이 늘면 Cloud Run/Fly.io 같은 별도 서비스로 이전한다.
