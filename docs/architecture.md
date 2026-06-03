# 가족/친구 위치공유 앱 기술 아키텍처

## 1. 목표와 기본 원칙

이 앱은 가족, 친구, 보호자와 피보호자가 서로 동의한 범위 안에서 현재 위치, 이동 기록, 장소 출입, 긴급 상황을 확인하는 iOS/Android 앱이다. 기존 위치공유 앱들이 구독으로 제한하는 기능을 기본 무료로 제공하고, 수익은 광고를 중심으로 만든다.

핵심 원칙은 다음과 같다.

- 안전 기능은 광고, 결제, 가입 유도 때문에 막히면 안 된다.
- 위치 데이터는 민감정보에 준해 다루고, 공유 범위와 삭제 권한을 사용자가 직접 통제해야 한다.
- 배터리와 권한 정책이 제품 품질을 결정하므로, "항상 GPS 켜기"가 아니라 상태 기반 위치 수집으로 설계한다.
- MVP부터 위치기반서비스 약관, 개인정보 처리방침, 아동/청소년 보호자 동의, 광고 동의, 데이터 삭제 프로세스를 제품 플로우에 포함한다.

## 2. 권장 스택

### Expo/React Native

장점:

- TypeScript 기반으로 웹/백엔드와 인력 풀을 맞추기 쉽다.
- Expo를 쓰면 초기 화면, 알림, OTA 업데이트, 빌드 파이프라인을 빠르게 구성할 수 있다.
- Firebase, Supabase, AdMob, 지도 SDK 연동 사례가 많다.

주의점:

- 백그라운드 위치, 지오펜스, Android foreground service, iOS `Always` 권한처럼 네이티브 정책을 깊게 다뤄야 하는 기능은 Expo managed만으로는 한계가 빨리 온다.
- Expo config plugin, development build, native module 유지보수가 필요해지면 초기 단순성이 줄어든다.
- 위치 수집 신뢰성이 제품 핵심인 앱에서는 OS별 예외 처리와 배터리 전략을 네이티브에 가깝게 제어해야 한다.

### Flutter

장점:

- iOS/Android 단일 코드베이스에서 UI 일관성이 높고 성능 예측이 쉽다.
- 플랫폼 채널을 통해 iOS `CLLocationManager`, Android Fused Location Provider/Foreground Service를 명확하게 감쌀 수 있다.
- `google_mobile_ads`, Firebase, Crashlytics, Remote Config, 지도 SDK 연동이 안정적이다.
- Node/npm 의존 없이 Dart/Flutter 중심으로 앱 개발을 시작할 수 있다.

주의점:

- 백그라운드 위치는 Flutter 플러그인만 믿지 말고, 제품 핵심 경로는 네이티브 브리지로 고정하는 편이 안전하다.
- 네이티브 권한 문구, 배터리 최적화 예외, 제조사별 Android 정책 대응에는 별도 테스트가 필요하다.
- 웹/관리자 콘솔을 별도로 만들 경우 프론트엔드 스택이 하나 더 필요할 수 있다.

### 추천

**Flutter를 추천한다.** 이 제품의 핵심 리스크는 UI 생산성보다 백그라운드 위치 안정성, 배터리, 권한, 광고 SDK와 위치 데이터의 분리다. Flutter는 빠른 크로스플랫폼 개발과 네이티브 제어의 균형이 좋고, 필요할 때 iOS/Android 위치 엔진만 네이티브 모듈로 단단히 만들 수 있다.

권장 앱 구성:

- App: Flutter, Dart, Riverpod, go_router, freezed/json_serializable, dio, drift 또는 sqflite, secure_storage
- Native location bridge: iOS Swift, Android Kotlin
- 지도: 한국 우선이면 Naver/Kakao 지도 검토, 글로벌 확장이 있으면 Google Maps 또는 Mapbox 우선
- 광고: Google AdMob, Google UMP, iOS ATT
- 분석/품질: Firebase Crashlytics, Performance, Remote Config, 최소한의 Analytics
- 푸시: Firebase Cloud Messaging, iOS APNs 연동

## 3. 백엔드 아키텍처

### 전체 구조

MVP에서는 관리형 서비스를 적극 활용하되, 위치 데이터와 동의 정책은 별도 API 서버가 소유한다.

- API Gateway: HTTPS REST API, WebSocket 진입점
- Auth: Firebase Auth 또는 Supabase Auth
- API Service: Cloud Run/Fargate/Fly.io 같은 컨테이너 런타임
- Database: PostgreSQL + PostGIS
- Cache/PubSub: Redis
- Realtime: WebSocket 서버 또는 Supabase Realtime/Pusher 계열
- Push: FCM/APNs
- Object Storage: SOS 음성, 프로필 이미지, 감사 로그 내보내기 파일
- Jobs: 위치 히스토리 다운샘플링, 보존기간 삭제, 지오펜스 재평가, 데이터 삭제 작업
- Admin: 사용자 신고, 삭제 요청, SOS 오남용, 장애 대응용 내부 콘솔

Firebase 단독 구조도 가능하지만, 장기 위치 기록, 반경 검색, 지오펜스 판정, 삭제 감사 추적은 PostgreSQL/PostGIS가 더 예측 가능하다. Firestore는 실시간 최신 위치 캐시에는 편하지만, 위치 히스토리와 삭제/보존 정책을 정교하게 운영할수록 비용과 쿼리 제약이 커진다.

### 인증

지원 방식:

- 휴대폰 번호 인증
- Apple 로그인
- Google 로그인
- 선택: Kakao/Naver 로그인

설계 포인트:

- `users`는 사람 단위 계정이고, `devices`는 설치된 앱 단위다.
- 위치 업로드는 사용자 토큰만 보지 않고 device binding을 함께 검증한다.
- 미성년자 또는 보호 대상 프로필은 보호자 동의 상태를 별도로 가진다.
- 계정 탈퇴, 기기 분실, 번호 변경 시 기존 세션을 원격 폐기할 수 있어야 한다.

### 서클/멤버

서클은 가족, 여행, 친구 모임처럼 위치를 공유하는 단위다.

기능:

- 초대 링크 또는 초대 코드
- 멤버 역할: owner, admin, member, dependent
- 공유 상태: on, paused, approximate, sos_only
- 권한 범위: 현재 위치 보기, 히스토리 보기, 장소 알림 관리, SOS 수신, 관리자 권한
- 투명성: 누가 내 위치를 볼 수 있는지 항상 확인 가능

차별화 포인트:

- "일시 서클": 여행/행사용으로 종료 시간이 있는 서클
- "보기 영수증": 내 위치를 누가 언제 조회했는지 요약 표시
- "프라이버시 시간표": 특정 시간대에는 대략 위치만 공유

### 위치 업데이트/히스토리

위치 흐름:

1. 앱이 OS 위치 엔진에서 위치를 받는다.
2. 앱은 정확도, 배터리, 이동 상태, 네트워크 상태를 보고 업로드 여부를 결정한다.
3. API는 토큰, device id, consent version, sharing status를 검증한다.
4. 최신 위치는 `locations_current`에 upsert한다.
5. 원본 포인트는 `location_points`에 append한다.
6. Redis/WebSocket으로 같은 서클의 구독자에게 최신 위치 이벤트를 발행한다.
7. 지오펜스, 배터리 부족, 비활성 알림은 비동기 잡에서 처리한다.

저장 전략:

- 최신 위치: 빠른 조회용 단일 row
- 원본 히스토리: 일 단위 또는 월 단위 파티션
- 다운샘플 히스토리: 1분/5분/1시간 단위 요약
- 기본 보존기간: MVP 30일, 이후 사용자 설정으로 90일/365일 확장 가능
- 안전 기능은 무료지만, 비용 관리를 위해 오래된 데이터는 자동 요약 또는 삭제한다.

### 지오펜스

장소 알림은 앱과 서버가 함께 처리한다.

- 앱: OS 지오펜스 API로 배터리 효율적인 출입 감지
- 서버: 위치 업로드 시 PostGIS로 fallback 판정
- 중복 방지: 같은 장소의 arrive/leave 이벤트는 최소 쿨다운을 둔다.
- 흔들림 방지: 반경 경계에서 GPS가 튀는 문제를 막기 위해 hysteresis를 적용한다.
- 권한: 장소 생성자와 알림 수신자를 분리한다.

### SOS

SOS는 광고나 일반 API 큐에 의존하지 않는 고우선 경로로 둔다.

기능:

- 앱 내 긴급 버튼, 선택적으로 흔들기 감지
- 현재 위치, 배터리, 속도, 마지막 이동 방향, 네트워크 상태 전송
- 수신자에게 high priority push
- 선택: 짧은 음성 클립 첨부, 보호자/지정 연락처 SMS 연동
- 선택: 112/119 직접 연결 안내. 자동 신고는 법적 검토 후 별도 단계에서만 도입한다.

주의점:

- SOS 화면에는 광고를 표시하지 않는다.
- 음성 녹음은 명시적 마이크 권한과 별도 동의가 필요하다.
- SOS 음성/첨부 데이터는 짧은 보존기간을 기본값으로 한다.

### 광고/동의

광고는 제품 기능을 잠그지 않는 방식으로만 사용한다.

구현:

- AdMob 배너, 네이티브 광고, 제한적인 전면 광고
- Google UMP로 GDPR/EEA 동의 처리
- iOS ATT 권한 요청은 앱 가치 설명 이후 별도 화면에서 요청
- 아동/청소년 또는 보호 대상 계정은 개인화 광고를 끄고, 연령 적합 광고만 허용
- 광고 SDK에는 앱의 정밀 위치 데이터를 직접 전달하지 않는다.

광고 배치 원칙:

- 지도 하단 배너는 가능하지만 위치 마커와 SOS 버튼을 가리면 안 된다.
- 장소 알림, 히스토리 목록, 설정 하단에는 네이티브 광고를 둘 수 있다.
- SOS, 권한 요청, 온보딩, 개인정보 삭제, 안전 확인 플로우에는 광고를 넣지 않는다.
- 전면 광고는 사용자가 안전 관련 행동을 완료한 직후에는 금지한다.
- 빈번한 광고 로딩으로 배터리와 네트워크를 낭비하지 않도록 Remote Config로 빈도를 제어한다.

### 개인정보 삭제

삭제 범위:

- 계정 삭제
- 특정 서클 탈퇴
- 내 위치 히스토리 삭제
- 특정 기간 히스토리 삭제
- 기기 연결 해제
- SOS 첨부 삭제

처리 방식:

- API에서 삭제 요청을 생성하고 `privacy_deletion_requests`에 기록한다.
- 즉시 접근 차단이 필요한 데이터는 soft delete와 권한 폐기를 먼저 수행한다.
- 파티션 데이터, 캐시, 객체 스토리지, 검색 인덱스, 백업 삭제는 비동기 잡으로 처리한다.
- 완료 후 사용자에게 결과를 알리고, 내부 감사 로그에는 최소한의 삭제 증적만 남긴다.
- 법적 보존이 필요한 항목은 사유와 기간을 분리 저장한다.

## 4. 데이터 모델 초안

아래 모델은 PostgreSQL/PostGIS 기준 초안이다.

### users

- `id`: uuid
- `auth_provider`: phone, apple, google, kakao, naver
- `phone_hash`: nullable
- `display_name`
- `avatar_url`
- `birth_year`: nullable
- `guardian_user_id`: nullable
- `status`: active, suspended, deleted
- `created_at`, `updated_at`, `deleted_at`

### devices

- `id`: uuid
- `user_id`
- `platform`: ios, android
- `push_token`
- `app_version`
- `os_version`
- `device_model`
- `location_permission`: none, while_in_use, always, approximate
- `notification_permission`: granted, denied, unknown
- `battery_level`
- `is_charging`
- `last_seen_at`
- `revoked_at`

### circles

- `id`: uuid
- `name`
- `type`: family, friends, travel, care
- `owner_user_id`
- `expires_at`: nullable
- `created_at`, `updated_at`, `archived_at`

### circle_members

- `circle_id`
- `user_id`
- `role`: owner, admin, member, dependent
- `share_status`: on, paused, approximate, sos_only
- `can_view_history`: boolean
- `can_manage_places`: boolean
- `can_receive_sos`: boolean
- `joined_at`
- `left_at`

### invites

- `id`: uuid
- `circle_id`
- `inviter_user_id`
- `invite_code_hash`
- `expires_at`
- `max_uses`
- `used_count`
- `status`: active, revoked, expired

### locations_current

- `user_id`
- `device_id`
- `point`: geography(Point, 4326)
- `accuracy_m`
- `altitude_m`
- `speed_mps`
- `heading_deg`
- `activity`: still, walking, running, cycling, driving, unknown
- `battery_level`
- `source`: gps, wifi, cell, fused, manual, sos
- `recorded_at`
- `received_at`

### location_points

- `id`: bigserial
- `user_id`
- `device_id`
- `point`: geography(Point, 4326)
- `accuracy_m`
- `speed_mps`
- `heading_deg`
- `activity`
- `battery_level`
- `source`
- `recorded_at`
- `received_at`
- `consent_version`

운영에서는 `recorded_at` 기준 월별 파티션을 둔다.

### places

- `id`: uuid
- `circle_id`
- `creator_user_id`
- `name`
- `center`: geography(Point, 4326)
- `radius_m`
- `notify_on_arrive`
- `notify_on_leave`
- `active`
- `created_at`, `updated_at`

### geofence_events

- `id`: uuid
- `place_id`
- `user_id`
- `event_type`: arrive, leave
- `detected_by`: client, server
- `location_point_id`: nullable
- `occurred_at`
- `notified_at`

### sos_events

- `id`: uuid
- `sender_user_id`
- `circle_id`
- `location_point_id`: nullable
- `status`: active, acknowledged, resolved, canceled
- `message`: nullable
- `audio_url`: nullable
- `created_at`, `resolved_at`

### notification_events

- `id`: uuid
- `recipient_user_id`
- `type`: geofence, sos, low_battery, inactive, invite, system
- `payload`: jsonb
- `delivery_status`: queued, sent, failed, opened
- `created_at`, `sent_at`, `opened_at`

### consent_records

- `id`: uuid
- `user_id`
- `consent_type`: terms, privacy, location_terms, ads_personalization, guardian
- `version`
- `granted`
- `source`
- `created_at`

### ad_events

- `id`: uuid
- `user_id`: nullable
- `device_id`
- `placement`
- `ad_network`
- `event_type`: requested, loaded, shown, clicked, failed
- `non_personalized`: boolean
- `created_at`

### privacy_deletion_requests

- `id`: uuid
- `user_id`
- `request_type`: account, history, circle, device, sos_attachment
- `scope`: jsonb
- `status`: requested, processing, completed, failed
- `requested_at`, `completed_at`

## 5. API 설계 초안

REST API는 OpenAPI로 문서화하고, 모든 쓰기 API는 idempotency key를 받는다.

### Auth/Device

- `POST /v1/auth/session`: 클라이언트 auth token 교환
- `POST /v1/devices`: 기기 등록/갱신
- `PATCH /v1/devices/{deviceId}`: 권한, 배터리, 푸시 토큰 갱신
- `DELETE /v1/devices/{deviceId}`: 기기 연결 해제

### Circle/Member

- `POST /v1/circles`: 서클 생성
- `GET /v1/circles`: 내 서클 목록
- `GET /v1/circles/{circleId}`: 서클 상세
- `PATCH /v1/circles/{circleId}`: 서클 수정
- `POST /v1/circles/{circleId}/invites`: 초대 생성
- `POST /v1/invites/{code}/accept`: 초대 수락
- `PATCH /v1/circles/{circleId}/members/{userId}`: 역할/공유 상태 변경
- `DELETE /v1/circles/{circleId}/members/me`: 탈퇴

### Location

- `POST /v1/locations/batch`: 위치 포인트 배치 업로드
- `GET /v1/circles/{circleId}/locations/current`: 멤버 최신 위치
- `GET /v1/users/{userId}/locations/history?from=&to=&granularity=`: 권한 있는 히스토리 조회
- `POST /v1/users/me/location/pause`: 위치 공유 일시정지
- `POST /v1/users/me/location/resume`: 위치 공유 재개

### Places/Geofence

- `POST /v1/circles/{circleId}/places`: 장소 생성
- `GET /v1/circles/{circleId}/places`: 장소 목록
- `PATCH /v1/places/{placeId}`: 장소 수정
- `DELETE /v1/places/{placeId}`: 장소 삭제
- `POST /v1/geofence-events`: 클라이언트 감지 이벤트 업로드

### SOS

- `POST /v1/sos`: SOS 생성
- `POST /v1/sos/{sosId}/ack`: 수신 확인
- `POST /v1/sos/{sosId}/resolve`: 해결 처리
- `POST /v1/sos/{sosId}/audio-upload-url`: 음성 첨부 업로드 URL 생성

### Consent/Privacy/Ads

- `GET /v1/consents/required`: 필요한 약관/동의 버전 조회
- `POST /v1/consents`: 동의 기록
- `GET /v1/privacy/export`: 내 데이터 내보내기 요청
- `DELETE /v1/privacy/account`: 계정 삭제 요청
- `DELETE /v1/privacy/location-history`: 위치 히스토리 삭제 요청
- `POST /v1/ad-events`: 광고 이벤트 기록

## 6. 실시간 채널 설계

WebSocket 또는 managed realtime 채널을 사용한다. 채널 구독은 서버가 매번 권한을 검증하고, 멤버십 변경 시 즉시 revoke한다.

채널:

- `circle:{circleId}:locations`: 멤버 최신 위치 변경
- `circle:{circleId}:presence`: 앱 온라인/오프라인, 마지막 접속
- `circle:{circleId}:events`: 장소 출입, 배터리 부족, 비활성 알림
- `user:{userId}:private`: 초대, 권한 변경, 계정/삭제 상태
- `sos:{sosId}`: SOS 상태 변경

이벤트 예시:

```json
{
  "type": "location.updated",
  "circleId": "uuid",
  "userId": "uuid",
  "location": {
    "lat": 37.5665,
    "lng": 126.978,
    "accuracyM": 24,
    "activity": "walking",
    "batteryLevel": 0.72,
    "recordedAt": "2026-05-30T09:00:00Z"
  }
}
```

전송 최적화:

- 지도 화면을 보고 있는 멤버에게만 고빈도 업데이트
- 백그라운드 구독자는 push 중심
- 위치가 거의 변하지 않으면 heartbeat만 전송
- 같은 사용자의 이벤트는 순서 보장을 위해 `recorded_at`과 sequence를 함께 사용

## 7. iOS/Android 위치 권한과 배터리 전략

### iOS

필요 권한:

- `When In Use Location`
- `Always Location`은 온보딩 이후, 실제 가치 설명 후 단계적으로 요청
- `Precise Location` 비활성 상태 대응
- Push Notification
- 선택: Microphone for SOS audio

구현:

- `CLLocationManager`
- Background Modes의 Location updates
- Significant Location Change
- Region Monitoring
- Visits API 검토
- `allowsBackgroundLocationUpdates`는 공유 on 상태에서만 활성화
- `pausesLocationUpdatesAutomatically`와 `activityType`을 이동 상태에 맞게 조정

주의점:

- iOS는 사용자가 언제든 `Always`를 `While Using`으로 낮출 수 있으므로 앱 내 상태와 안내가 필요하다.
- 백그라운드 위치 표시 문구와 권한 설명은 심사에서 중요하다.
- 정밀 위치가 꺼진 경우 approximate 공유로 표시하고, 안전 기능 한계를 명확히 알려야 한다.

### Android

필요 권한:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `POST_NOTIFICATIONS`
- Foreground service location type
- 선택: `ACTIVITY_RECOGNITION`

구현:

- Fused Location Provider
- Geofencing API
- Foreground Service with persistent notification
- WorkManager for deferred sync
- Doze/App Standby 대응
- 제조사별 배터리 최적화 제한 안내

주의점:

- Android 10 이상은 background location을 별도 단계로 요청해야 한다.
- Android 13 이상은 알림 권한이 없으면 foreground service 경험이 나빠진다.
- Android 14 이상은 foreground service type과 권한 선언을 정확히 맞춰야 한다.
- 배터리 최적화 예외 요청은 남용하지 말고, 위치 공유 품질 문제가 확인될 때 안내한다.

### 배터리 전략

위치 수집 모드:

- Stationary: 이동 없음. significant change, geofence 중심. 업로드 10~30분 간격.
- Walking/Transit: 중간 정확도. 1~5분 간격.
- Driving: 속도 변화와 거리 기준. 15~60초 간격, 단 배터리 하한선 적용.
- Active viewing: 가족이 지도에서 보고 있을 때 일시적으로 고빈도.
- SOS: 최고 정확도, 즉시 업로드.
- Low battery: 업로드 간격 증가, geofence 중심.

업로드 정책:

- 거리 기준: 50~200m 이상 이동 시 업로드
- 시간 기준: 상태별 최소/최대 간격
- 정확도 기준: 정확도가 너무 낮은 포인트는 최신 위치에는 반영하되 히스토리에는 별도 표시
- 배치 업로드: 네트워크가 불안정하면 로컬 큐에 저장 후 재전송
- 서버 rate limit: 기기당 초당/분당 제한

앱 표시:

- 각 멤버의 "마지막 업데이트 시각", "정확도", "배터리", "권한 문제"를 지도에 투명하게 표시한다.
- 사용자가 위치 공유를 끄거나 일시정지하면 다른 멤버에게 숨기지 말고 "공유 일시정지" 상태로 표시한다.

## 8. 무료 전체 기능 + 광고 모델 주의점

무료 전체 기능 전략은 사용자 신뢰를 만들 수 있지만, 위치 앱에서는 광고 수익만으로 고빈도 위치 저장 비용을 감당하기 어렵다. 따라서 기능은 무료로 열되, 비용 구조를 제품 설계로 제어해야 한다.

구현상 주의점:

- 히스토리 무제한 원본 저장은 피하고, 오래된 데이터는 요약 저장 또는 사용자 선택 보존으로 전환한다.
- 광고는 기능 unlock 수단이 아니라 운영비 보조 수단이어야 한다.
- 개인화 광고 동의를 받더라도 정밀 위치 데이터를 광고 타게팅에 넘기지 않는다.
- 아동 사용 가능성이 있으므로 Google Play 가족 정책, COPPA, 국내 개인정보/위치정보 규정 검토가 필요하다.
- 광고 SDK 초기화는 동의 상태 확정 후 수행한다.
- 광고 실패가 앱 기능 실패로 전파되지 않게 완전히 분리한다.
- Remote Config로 placement, frequency cap, 국가별 노출 여부를 제어한다.
- 안전 기능 화면, SOS, 권한 설정, 삭제/탈퇴에는 광고를 제거한다.

수익 보완 옵션:

- 기능 제한 없는 선택형 후원/광고 제거 상품은 장기적으로 검토 가능하다.
- B2B 제휴, 학교/요양기관용 관리 콘솔은 별도 제품으로 분리한다.
- 지도/거리뷰처럼 외부 API 비용이 큰 기능은 캐싱, 호출 제한, 대체 provider를 준비한다.

## 9. MVP 범위

1차 MVP:

- 회원가입/로그인
- 기기 등록과 푸시 토큰 관리
- 서클 생성/초대/탈퇴
- 실시간 최신 위치 지도 표시
- 위치 공유 on/off/일시정지
- 장소 등록과 출입 알림
- 7~30일 위치 히스토리
- SOS 버튼과 high priority push
- 배터리 부족 알림
- 광고 동의와 기본 배너/네이티브 광고
- 계정 삭제와 위치 히스토리 삭제
- Crashlytics, 기본 운영 대시보드

MVP에서 제외하거나 제한:

- 365일 원본 히스토리
- 운전 습관 정밀 분석
- 음성 포함 SOS 자동 녹음
- 웹 관제 콘솔
- 분실폰 복구 특화 모드
- 실시간 채팅/워키토키

## 10. MVP 이후 확장 로드맵

### Phase 1: 신뢰성과 안전성 강화

- 제조사별 Android 백그라운드 위치 품질 개선
- 지오펜스 중복/오탐 감소
- 위치 정확도 설명 UI
- 보호자 동의 플로우 고도화
- 삭제 요청 처리 자동화와 감사 로그

### Phase 2: 차별화 기능

- 일시 서클과 여행 모드
- 대략 위치/프라이버시 시간표
- 위치 조회 영수증
- 귀가/도착 ETA 공유
- 비활성 알림: 장시간 휴대폰 미사용, 충전 중단, 이동 없음
- 안전 체크인: 특정 시간까지 응답 없으면 보호자 알림

### Phase 3: 고급 위치/돌봄

- 운전 리포트: 급가속, 급감속, 과속, 야간 운전
- 노인 돌봄 모드: 생활 반경 이탈, 장시간 미사용, 정기 안부
- 분실폰 모드: 마지막 위치, 소리 울림, 배터리 절약 추적
- Wear OS/Apple Watch 연동
- 웹 지도 뷰어

### Phase 4: 운영/사업 확장

- 국가별 지도 provider 최적화
- 학교/요양기관용 B2B 콘솔
- 가족 안전 리포트 월간 요약
- 광고 mediation과 국가별 eCPM 최적화
- 데이터 보존 정책 국가별 분리

## 11. 검수와 디버깅 체크리스트

위치 앱은 일반 앱보다 실제 기기 검수가 중요하다.

- iOS: foreground, background, 잠금화면, 앱 강제 종료, 저전력 모드, 정밀 위치 off
- Android: foreground service, Doze, 배터리 최적화, 제조사별 백그라운드 제한
- 네트워크: 오프라인 큐, 재전송, 중복 업로드, 순서 역전
- 권한: while-in-use만 허용, always 거부, 알림 거부, 마이크 거부
- 안전: SOS push 지연, 수신자 없음, 위치 없음, 음성 첨부 실패
- 개인정보: 공유 일시정지, 서클 탈퇴, 계정 삭제, 히스토리 삭제
- 광고: 동의 전 SDK 초기화 방지, 아동/비개인화 광고, 광고 실패 격리
- 비용: 위치 업로드 빈도, DB 파티션 크기, 지도 API 호출량, push 발송량

## 12. 참고한 공개 서비스

- [iSharing 공식 웹사이트](https://isharingsoft.com/ko/)
- [iSharing Google Play 페이지](https://play.google.com/store/apps/details?id=com.isharing.isharing&pli=1)

