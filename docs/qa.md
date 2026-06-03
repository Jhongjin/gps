# QA/정책/검수 계획

대상: 가족/친구 위치공유 앱(iOS/AOS), 모든 기능 무료 제공, 광고 기반 수익화 모델  
검수 기준일: 2026-05-30(KST)  
핵심 원칙: 위치 데이터는 앱의 안전/위치공유 기능에만 사용하고, 광고 타게팅/광고 SDK 전달에는 사용하지 않는다.

## 공식 정책 참고

- Apple App Review Guidelines: https://developer.apple.com/kr/app-store/review/guidelines/
- Apple User Privacy and Data Use: https://developer.apple.com/app-store/user-privacy-and-data-use/
- Apple App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Apple Kids/Age-appropriate Experiences: https://developer.apple.com/kids/
- Google Play User Data: https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play Location Permissions: https://support.google.com/googleplay/android-developer/answer/16558241
- Google Play Background Location: https://support.google.com/googleplay/android-developer/answer/9799150
- Google Play Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469
- Google Play Families/Data Practices: https://support.google.com/googleplay/android-developer/answer/11043825
- Google Play Developer Program Policy(Ads/Families 포함): https://support.google.com/googleplay/android-developer/answer/17105854

정책은 수시로 바뀌므로 App Store/Google Play 제출 직전 위 링크를 재확인한다.

## 기능 QA 매트릭스

| 영역 | 주요 검증 포인트 | 테스트 케이스 | 합격 기준 | 관측/자동화 |
| --- | --- | --- | --- | --- |
| 권한 | 위치, 백그라운드 위치, 정확한 위치, 알림, 연락처, 광고 추적 권한의 순서와 고지 | 최초 실행, 초대 수락, 위치공유 시작, 지오펜스 생성, SOS 사용 시 권한 요청 타이밍 확인 | 기능 사용 직전 명확한 설명 후 권한 요청. 거부 시 제한 모드와 재시도 경로 제공. 권한 강요/조작 없음 | `permission_prompt_shown`, `permission_result`, 권한 상태 스냅샷 |
| 권한 | iOS When In Use -> Always 승격, Android Foreground -> Background Location 분리 | iOS에서 Always 요청 전 사전 설명, Android에서 앱 내 고지 후 런타임 권한 요청 | 배경 위치 필요성이 사용자에게 명확하고, 스토어 고지/앱 내 고지/권한 문구가 일관됨 | 권한 퍼널 전환율, 거부율, OS별 오류 코드 |
| 권한 | 정확한 위치/대략적 위치 대응 | iOS Precise off, Android approximate only 상태에서 지도/초대/지오펜스/SOS 확인 | 대략적 위치에서는 정확도 원 표시와 제한 안내 제공. 정밀 위치가 필수인 기능만 별도 요청 | `location_accuracy_bucket`, `feature_limited_reason` |
| 배경 위치 | 앱 전경/백그라운드/종료/재부팅 상태에서 위치 갱신 | 정상 이동, 정지, 지하/실내, 앱 강제 종료, 기기 재부팅, OS 업데이트 후 확인 | 공유 중 상태가 끊기지 않고, 끊긴 경우 "마지막 업데이트"와 원인을 명확히 표시 | `location_update_attempt`, `location_update_success`, `location_update_failure` |
| 배경 위치 | 배터리/발열/데이터 사용량 | 4시간 이동, 24시간 일상 사용, 저전력 모드, 배터리 최적화 ON/OFF | 배터리 소모가 허용 목표 내. 불필요한 연속 GPS 사용 없음. 저전력 상태에서 갱신 주기 완화 | 배터리 소모율, 업데이트 간격, foreground service 상태 |
| 배경 위치 | Google Play 심사용 재현성 | 배경 위치 핵심 기능 하나를 선택해 심사용 영상/계정으로 재현 | Play Console 선언, 앱 내 고지, 런타임 권한, 배경 동작이 30초 내 영상에서 확인 가능 | 제출 전 체크리스트, 심사 계정 상태 |
| 지오펜스 | 생성/수정/삭제/반경/중복 알림 | 집/학교/회사 반경 100m/200m/500m, 경계선 왕복, 터널/고층 건물 | 진입/이탈 알림이 중복 폭주하지 않고, 정확도 낮을 때 보류/재검증 | `geofence_registered`, `geofence_transition_detected`, `geofence_notification_sent` |
| 지오펜스 | 권한/OS 제한 | 위치 권한 없음, 배경 권한 없음, 알림 권한 없음, Android 배터리 최적화 | 기능 불가 원인을 정확히 안내하고 대체 경로 제공 | 지오펜스 실패 사유 코드 |
| SOS | 긴급 버튼 UX와 오작동 방지 | 길게 누르기, 카운트다운 취소, 잠금/백그라운드, 네트워크 불안정 | 실수 방지와 빠른 발동 균형. SOS 중 광고/가입/권한 팝업으로 흐름 차단 금지 | `sos_started`, `sos_cancelled`, `sos_sent`, `sos_acknowledged`, `sos_failed` |
| SOS | 전달 신뢰성 | 원형 그룹 1명/5명/20명, 푸시 실패, SMS/딥링크 대체, 오프라인 큐 | 온라인 정상 조건에서 목표 시간 내 알림 전달. 실패 시 재시도와 상태 표시 | SOS 전달 지연, 푸시 성공률, 재시도 횟수 |
| 초대 | 링크/QR/연락처 초대 | 초대 생성, 만료, 재사용, 잘못된 링크, 다른 계정 수락, 탈퇴 후 재초대 | 초대 토큰은 추측 불가/만료 가능/취소 가능. 양방향 동의 전 위치 노출 없음 | `invite_created`, `invite_opened`, `invite_accepted`, `invite_revoked` |
| 초대 | 미성년자/보호자 흐름 | 보호자 초대, 가족 그룹 가입, 미성년 계정 동의 철회 | 보호자 동의와 설명이 명확하고, 미성년자 데이터 공유 범위가 제한됨 | 나이/동의 상태 플래그, 감사 로그 |
| 지도 | 위치 표시/정확도/상태 | 현재 위치, 친구 위치, 오래된 위치, 정확도 원, 클러스터링, 지도 줌/회전 | 마커 점프 최소화. 오래된 위치는 실시간처럼 보이지 않게 표시. 정확도 원 제공 | `map_loaded`, `map_marker_rendered`, `map_tile_error` |
| 지도 | 지도 제공자 장애 | 지도 타일 실패, API 쿼터 초과, 네트워크 끊김 | 빈 화면 대신 캐시/오류 UI. 핵심 안전 상태는 지도 장애와 독립 표시 | 지도 로딩 시간, 타일 실패율 |
| 기록 | 위치 기록 저장/조회/삭제 | 일/주/월 기록, 특정 멤버 기록, 기록 꺼짐, 삭제/계정 삭제 | 보관 기간과 목적이 명확. 삭제 후 앱/서버/백업 정책에 맞게 제거 | `history_viewed`, `history_deleted`, `retention_purge_completed` |
| 기록 | 민감 정보 보호 | 주소/방문 패턴/학교/집 노출, 스크린샷 공유 | 최소한의 기간과 범위만 표시. 공유 대상별 접근권한 검증 | 접근 거부 로그, 권한 위반 알림 |
| 광고 | 위치 데이터와 광고 분리 | 광고 SDK 네트워크 트래픽, SDK 설정, 광고 요청 파라미터 검사 | 정밀/배경 위치, 지오펜스, SOS, 가족 구성 정보가 광고 SDK로 전달되지 않음 | 프록시 검사, SDK 이벤트, 데이터 유출 스캔 |
| 광고 | 광고 UX | 배너/네이티브/전면 광고, 빈 광고, 광고 로딩 지연 | SOS, 권한 요청, 초대 수락, 위치공유 시작, 개인정보 설정 화면에는 방해 광고 없음 | `ad_request`, `ad_loaded`, `ad_impression`, `ad_error` |
| 광고 | 아동/동의 상태별 처리 | 13세 미만, 동의 미확인, ATT 거부, AAID 제한, GDPR/CCPA 지역 | 개인화 광고/리마케팅/광고 ID 수집 차단. 필요한 경우 아동용 승인 SDK만 사용 | 동의 상태, 광고 요청 태그, IDFA/AAID 접근 여부 |
| 오프라인 | 네트워크 없음/서버 장애 | 비행기 모드, 2G/3G, DNS 실패, API 5xx, 푸시 장애 | 위치/SOS/지오펜스 이벤트를 안전하게 큐잉하고 재전송. 중복 전송 방지 | `offline_queue_enqueued`, `offline_queue_flushed`, API 에러율 |
| 저전력 | OS 제한 대응 | iOS Low Power Mode, Android Doze, 배터리 최적화, 백그라운드 데이터 제한 | 상태가 사용자에게 표시되고, 가능한 범위에서 업데이트 주기 조정. 강제 설정 유도 없음 | `battery_saver_detected`, 업데이트 간격 변화 |
| 네트워크 오류 | 동기화/충돌 | 다중 기기 로그인, 시간 오차, 중복 이벤트, 지연 도착 | 서버 타임스탬프 기준 정렬. 오래된 위치가 최신 위치를 덮어쓰지 않음 | 이벤트 idempotency key, server clock skew |

## 개인정보/아동/광고/스토어 심사 체크리스트

### 개인정보/보안

- [ ] 데이터 맵 작성: 정밀 위치, 대략 위치, 위치 기록, 지오펜스, SOS, 초대 토큰, 연락처, 계정 정보, 푸시 토큰, 광고 ID, 진단 로그를 목적별로 분류한다.
- [ ] 목적 제한: 위치 데이터는 위치공유, 지오펜스, SOS, 안전 알림에만 사용한다.
- [ ] 데이터 최소화: 기능별 최소 권한을 요청하고, 연락처 전체 업로드 대신 선택형 초대/공유 시트를 우선한다.
- [ ] 기본값: 위치 기록은 기본 보관 기간을 짧게 설정하고, 장기 기록은 명시적 선택으로 분리한다.
- [ ] 암호화: 전송 구간은 TLS, 서버 저장 위치/토큰/초대 정보는 암호화 또는 강한 접근통제로 보호한다.
- [ ] 접근통제: 그룹 멤버십, 보호자 권한, 탈퇴/차단/일시정지 상태를 서버에서 강제 검증한다.
- [ ] 사용자 통제: 위치공유 일시정지, 특정 멤버 차단, 그룹 탈퇴, 기록 삭제, 계정 삭제, 데이터 삭제 요청 경로를 제공한다.
- [ ] 삭제 정책: 앱 내 계정 삭제와 서버 데이터 삭제/익명화/백업 보관 예외를 개인정보 처리방침에 명시한다.
- [ ] 앱 내 고지: 배경 위치 수집 전, 어떤 데이터가 어떤 기능에 쓰이고 누구에게 공유되는지 별도 화면에서 설명한다.
- [ ] 개인정보 처리방침: 앱/서비스명, 법인명, 수집 데이터, 목적, 공유 대상, 광고/분석 SDK, 보관 기간, 삭제 방법, 문의처를 포함한다.
- [ ] 로그 원칙: 분석/크래시 로그에는 원시 위도/경도, 주소, 전화번호, 초대 토큰, 아동 식별 정보를 남기지 않는다.
- [ ] 위치기반서비스 법무: 한국 출시 시 위치정보법, 개인정보보호법, 만 14세 미만 동의 요건을 법무 검토한다.

### 아동/미성년자

- [ ] 타깃 연령 결정: 앱이 "아동 대상"인지, "보호자 중심 가족 안전 앱"인지 출시 전 명확히 정한다.
- [ ] Google Play에서 아동을 타깃으로 포함하면 Families 정책 적용 대상이다. 아동 대상 앱의 위치 권한/광고 ID/광고 SDK 사용은 고위험이므로 법무와 사전 검토한다.
- [ ] 미성년자가 독립적으로 타인의 위치를 조회하거나 본인 위치를 공유하기 전에 보호자 동의/초대/관리 흐름을 요구한다.
- [ ] 중립적 나이 확인 화면을 사용한다. 나이 입력을 광고 최적화 목적으로 사용하지 않는다.
- [ ] 아동 또는 동의 미확인 사용자의 AAID/IDFA/지속 식별자 전송을 차단한다.
- [ ] 아동/미성년자에게 개인화 광고, 리마케팅, 관심 기반 광고를 제공하지 않는다.
- [ ] Apple Kids Category로 제출하는 경우 타사 광고/분석 제한, parental gate, 연령 적합성, 개인정보 처리방침 요건을 별도 충족한다.
- [ ] 앱 메타데이터에 "어린이용", "아동용" 등 표현을 쓰는 경우 Kids Category/Google Families 요건과 일치해야 한다.
- [ ] 가족 구성원 위치 조회는 양방향 동의와 철회 가능성을 갖춘다. 숨은 추적 기능은 금지한다.

### 광고

- [ ] 광고 SDK allowlist를 운영하고, 각 SDK의 데이터 수집/공유 항목을 App Privacy/Data Safety와 대조한다.
- [ ] 정밀 위치, 배경 위치, 지오펜스, SOS, 가족 관계, 집/학교 추정 정보는 광고 SDK에 전달하지 않는다.
- [ ] 광고 타게팅은 문맥형/비개인화 광고를 기본값으로 한다.
- [ ] iOS에서 IDFA 또는 앱 간 추적이 있으면 ATT를 사용하고, ATT 동의를 기능 접근 조건으로 삼지 않는다.
- [ ] Android에서 AAID를 사용하는 경우 용도는 광고/분석으로 제한하고, 영구 기기 식별자와 결합하지 않는다.
- [ ] GDPR/ePrivacy/CCPA/CPRA 등 적용 지역은 동의관리 플랫폼(CMP)을 적용하되, ATT 선택과 충돌하지 않도록 한다.
- [ ] SOS, 긴급 연락, 권한 요청, 개인정보 설정, 계정 삭제, 초대 수락 중에는 전면 광고를 띄우지 않는다.
- [ ] 전면 광고는 즉시 앱 실행 시 노출하지 않고, 닫기 버튼/빈도 제한/로딩 실패 처리를 검수한다.
- [ ] 리워드 광고는 안전 기능 잠금 해제 조건으로 사용하지 않는다. 모든 핵심 기능은 광고 시청 없이 사용 가능해야 한다.
- [ ] 광고 네트워크 개인정보처리방침 링크를 앱 개인정보 처리방침에 포함한다.

### App Store 심사

- [ ] Info.plist 위치 권한 문구가 구체적이다: 위치공유, 배경 업데이트, 지오펜스, SOS 목적을 분명히 적는다.
- [ ] Always 위치 권한은 실제 핵심 기능이 켜진 뒤 단계적으로 요청한다.
- [ ] App Store Connect App Privacy 라벨에 앱과 제3자 SDK가 수집하는 위치/식별자/진단/사용 데이터가 정확히 반영된다.
- [ ] Privacy Policy URL이 App Store Connect와 앱 내부에서 쉽게 접근 가능하다.
- [ ] 계정 생성이 있으면 앱 내 계정 삭제 기능을 제공한다.
- [ ] ATT 설명 화면은 투명하지만 동의 유도/강요/보상 제공이 없다.
- [ ] 위치 서비스는 앱 기능과 직접 관련된 경우에만 사용하고, 위치 데이터 수집/전송 전에 고지와 동의를 받는다.
- [ ] 미성년자 개인정보, 채팅/UGC, 광고 포함 여부가 연령 등급과 메타데이터에 반영된다.
- [ ] 리뷰 계정, 테스트 그룹, 배경 위치 재현 절차, 데모 영상을 App Review Notes에 제공한다.

### Google Play 심사

- [ ] `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `POST_NOTIFICATIONS`, `FOREGROUND_SERVICE_LOCATION`, `AD_ID` 사용 여부를 매 빌드 확인한다.
- [ ] 배경 위치를 요청하면 앱 내 prominent disclosure가 런타임 권한보다 먼저 표시된다.
- [ ] 배경 위치 고지는 "location"과 "background/when the app is closed/when the app is not in use"에 해당하는 문구를 포함한다.
- [ ] Play Console Background Location 선언은 핵심 기능 하나를 선택해 설명한다. 권장 선택: 가족 안전 지오펜스/위치공유/SOS 중 가장 핵심인 하나.
- [ ] 제출 영상은 Android 기기에서 앱 내 고지, 런타임 권한, 배경 동작을 보여준다.
- [ ] Google Play 스토어 설명/스크린샷에 항상 켜진 위치공유 또는 배경 위치 기능이 명확히 드러난다.
- [ ] Data Safety에는 앱 및 SDK의 위치/식별자/진단/사용 데이터 수집/공유/암호화/삭제 요청 지원 여부를 정확히 표시한다.
- [ ] Target Audience and Content에서 아동 포함 여부, 광고 포함 여부, 가족 정책 준수 여부를 정확히 신고한다.
- [ ] 아동 또는 알 수 없는 연령 사용자에게 광고를 표시한다면 Families self-certified ads SDK만 사용한다.
- [ ] 개인정보 처리방침의 법인/앱명과 Google Play 등록 정보가 일치한다.

### 현재 구현 검수 포인트

- [ ] 지도에서 공유 정밀도/정확도 반경 원이 핀 아래에 표시된다.
- [ ] 5분 초과 위치는 `위치 업데이트 대기 중`, 30분 초과 위치는 `마지막 위치만 표시 중`으로 표시된다.
- [ ] 오래된 위치는 live route tail로 표시되지 않는다.
- [ ] 동행 중 `도착 확인`을 누르면 동행 공유가 종료되고 좌표 없는 안전 확인 이벤트가 준비된다.
- [ ] 안심 화면에서 Android/iOS 권한 스냅샷과 배터리 모드 컨트롤을 확인할 수 있다.
- [ ] Supabase `009_check_in_events.sql` 적용 전에는 체크인 RPC가 운영 DB에서 동작하지 않는다는 점을 릴리스 노트에 표시한다.

## 디버깅 로그/관측성 이벤트 설계

### 원칙

- 분석 이벤트에는 원시 위도/경도, 주소, 장소명, 연락처 원문, 초대 토큰, SOS 메시지 본문을 기록하지 않는다.
- 위치 품질은 `accuracy_bucket`(예: `<50m`, `50-200m`, `>200m`)과 `freshness_bucket`(예: `<1m`, `1-5m`, `5-30m`, `>30m`)으로만 분석한다.
- 사용자/그룹 식별자는 회전 가능한 해시 또는 내부 UUID를 사용하고, 운영자가 직접 개인을 식별할 수 없게 한다.
- 장애 대응용 원시 위치 조회는 별도 권한, 사유 입력, 감사 로그, 짧은 보관 기간을 둔다.
- 광고 분석 파이프라인과 위치 기능 파이프라인을 분리한다.
- 로그 보관 기본값: 제품 분석 90일 이하, 크래시 30일 이하, 보안 감사 로그는 법무 승인 기간. 실제 기간은 개인정보 처리방침과 일치시킨다.

### 공통 이벤트 필드

| 필드 | 설명 | 주의 |
| --- | --- | --- |
| `event_name` | 이벤트명 | 표준 사전 외 임의 이벤트 금지 |
| `event_id` | 중복 방지 UUID | 서버 idempotency에 사용 |
| `timestamp_client`, `timestamp_server` | 클라이언트/서버 시각 | 시간 오차 측정 |
| `platform`, `os_version`, `app_version`, `build_number` | 환경 정보 | 세부 기기 식별 최소화 |
| `device_model_bucket` | 기기군 | 개별 식별 가능한 희귀 모델 묶기 |
| `user_id_hash`, `circle_id_hash` | 비식별 해시 | 로그 외부 반출 금지 |
| `age_cohort` | `adult`, `teen`, `child`, `unknown` | 생년월일 원문 저장 금지 |
| `consent_state` | ATT/CMP/광고/위치/알림 동의 상태 | 정책 검증 핵심 |
| `permission_state` | 위치/알림/배경 권한 상태 | OS별 enum 매핑 |
| `network_type`, `battery_saver`, `low_power_mode` | 품질 분석 | 상태값만 저장 |
| `error_code`, `error_domain` | 실패 분석 | 서버/SDK 원문 메시지에 PII 포함 금지 |
| `latency_ms` | 처리 지연 | SOS/푸시/지도 핵심 |

### 이벤트 목록

| 이벤트 | 목적 | 주요 속성 | 금지 속성 |
| --- | --- | --- | --- |
| `onboarding_started` | 온보딩 이탈 분석 | 진입 경로, 언어, 국가 | 이름, 전화번호 |
| `permission_explanation_viewed` | 권한 설명 노출 확인 | 권한 종류, 기능명 | 위치 좌표 |
| `permission_prompt_shown` | OS 권한 요청 추적 | 권한 종류, 요청 단계 | OS 팝업 원문 캡처 |
| `permission_result` | 권한 허용/거부 | 결과, 이전 상태, 새 상태 | 사용자의 자유 입력 |
| `location_update_attempt` | 위치 갱신 시도 | 모드, 권한 상태, 배터리 상태 | 위도/경도 |
| `location_update_success` | 위치 품질/지연 분석 | accuracy bucket, freshness bucket, provider | 좌표, 주소 |
| `location_update_failure` | 장애 원인 분석 | error_code, provider, retry_count | 좌표, 장소명 |
| `background_location_session_started` | 배경 위치 세션 감사 | 시작 기능, 권한 상태 | 좌표 |
| `background_location_session_stopped` | 배터리/권한 대응 | 종료 사유, 지속 시간 | 좌표 |
| `geofence_registered` | 지오펜스 설정 품질 | 반경 bucket, 타입 | 집/학교 주소 |
| `geofence_transition_detected` | 진입/이탈 품질 | transition, confidence bucket | 좌표, 장소명 |
| `geofence_notification_sent` | 알림 전달률 | push provider, latency_ms | 수신자 이름 |
| `sos_started` | 긴급 흐름 분석 | 시작 화면, 네트워크 상태 | 메시지 본문 |
| `sos_cancelled` | 오작동/취소 분석 | 취소 시점, 카운트다운 잔여 | 좌표 |
| `sos_sent` | 전달 신뢰성 | 수신자 수 bucket, latency_ms | 좌표, 전화번호 |
| `sos_acknowledged` | 수신 확인 | ack_count bucket | 수신자 이름 |
| `invite_created` | 초대 퍼널 | 초대 방식, 만료 시간 bucket | 초대 토큰 |
| `invite_accepted` | 초대 성공 | 플랫폼, 그룹 크기 bucket | 연락처 원문 |
| `sharing_paused` | 프라이버시 제어 사용 | pause_duration bucket | 좌표 |
| `sharing_resumed` | 공유 재개 | 이전 pause 사유 | 좌표 |
| `history_viewed` | 기록 기능 사용 | 기간 bucket | 방문 장소 |
| `history_deleted` | 삭제 기능 검증 | 범위, 완료 여부 | 좌표 |
| `ad_request` | 광고 상태 | ad_unit, personalization flag, child_directed flag | 위치/가족 정보 |
| `ad_impression` | 수익/UX 분석 | ad_unit, format, screen | 위치/가족 정보 |
| `ad_error` | 광고 장애 | SDK, error_code | 광고 응답 원문 |
| `consent_status_changed` | 동의 감사 | ATT/CMP/ads state | 생년월일 |
| `offline_queue_enqueued` | 오프라인 안정성 | event_type, queue_size bucket | 원본 페이로드 |
| `offline_queue_flushed` | 복구 확인 | flushed_count bucket, retry_count | 원본 페이로드 |
| `account_deleted` | 삭제 요구 검증 | 삭제 방식, 완료 상태 | 삭제 전 데이터 원문 |
| `retention_purge_completed` | 보관 정책 준수 | 데이터 범주, 삭제 건수 bucket | 삭제 대상 원문 |

### 대시보드/알림

- 위치 업데이트 성공률: 플랫폼/OS/OEM/권한 상태별 1시간, 24시간 기준.
- 오래된 위치 비율: 공유 중 사용자 중 `freshness > 30분` 비율.
- SOS 전달 지연: p50/p95/p99, 실패율, 재시도 성공률.
- 지오펜스 알림 품질: 중복률, 누락 신고율, 반경별 오탐률.
- 권한 퍼널: 설명 화면 -> OS 권한 -> 배경 권한 -> 첫 위치공유 성공.
- 광고 안정성: fill rate, impression rate, crash-free sessions, 광고 화면별 이탈률.
- 개인정보 경보: 광고 요청에 위치 관련 파라미터 감지, 원시 좌표 로그 감지, 삭제 실패, 권한 없는 위치 조회.
- 릴리스 품질: crash-free users 99.5% 이상, ANR 0.3% 미만(Android 목표), SOS/위치 API 5xx 0.1% 미만.

## 베타 테스트 시나리오와 릴리스 차단 기준

### 베타 단계

1. 내부 알파(2주)
   - QA/개발/디자인/정책 담당자 중심.
   - 권한, 위치 갱신, 지오펜스, SOS, 광고 비활성/테스트 광고, 삭제 기능을 집중 검증.

2. 폐쇄 베타(4주)
   - 30~50개 가족/친구 그룹, iOS/Android 혼합.
   - Samsung, Pixel, Xiaomi/Oppo 계열, iPhone 구형/신형, 태블릿 일부 포함.
   - 실제 통학/출퇴근/여행/실내 환경에서 배경 위치와 배터리 측정.

3. 정책 베타/심사 리허설(1주)
   - App Store/Google Play 제출 자료, 권한 고지, 개인정보 라벨/Data Safety, 광고 SDK 스캔, 심사용 계정 검수.
   - Play Background Location 선언 영상과 Apple Review Notes를 제출 전 검증.

4. 제한 출시(2~4주)
   - 국가/언어/플랫폼 일부로 phased rollout.
   - 크래시, 위치 최신성, SOS 실패율, 광고 오류, 개인정보 요청 처리 SLA를 매일 확인.

### 핵심 시나리오

- 신규 사용자 A가 그룹을 만들고 사용자 B/C를 링크와 QR로 초대한다.
- B는 위치 권한을 허용하고, C는 거부한다. A 화면에서 각각의 상태가 정확히 표시된다.
- iOS 사용자가 When In Use만 허용한 뒤, 지오펜스/SOS를 켜며 Always 권한 승격 설명을 본다.
- Android 사용자가 Foreground 위치만 허용한 뒤, 배경 위치 기능을 켜며 prominent disclosure와 런타임 권한을 순서대로 본다.
- 사용자가 정확한 위치를 끄고 대략 위치만 허용한다. 지도/지오펜스가 제한 상태로 동작한다.
- 사용자가 4시간 이동한다. 위치 최신성, 배터리, 발열, 데이터 사용량을 확인한다.
- 저전력 모드/Doze/배터리 최적화 상태에서 위치 갱신 품질과 사용자 안내를 확인한다.
- 집/학교/회사 지오펜스를 만들고 실제 진입/이탈, 경계선 왕복, GPS 튐 상황을 검증한다.
- SOS를 발동하고 취소/재발동/오프라인/푸시 실패/수신 확인 흐름을 검증한다.
- 위치 공유를 일시정지하고 특정 멤버를 차단한 뒤 서버 API 직접 호출로도 위치 접근이 막히는지 확인한다.
- 기록 조회, 일부 삭제, 전체 삭제, 계정 삭제를 수행하고 서버/앱/대시보드 반영을 확인한다.
- 광고 동의 거부, ATT 거부, 아동/동의 미확인 상태에서 광고 요청 파라미터와 SDK 네트워크 트래픽을 확인한다.
- 앱 실행 직후, SOS 중, 권한 요청 직전, 개인정보 설정 화면에서 전면 광고가 뜨지 않는지 확인한다.
- 앱 업데이트 후 기존 권한/동의/공유 설정이 유지되고, 변경된 정책 고지가 필요한 경우 재동의가 뜨는지 확인한다.
- 서버 5xx, API 타임아웃, 지도 타일 장애, 푸시 제공자 장애를 주입해 fallback과 재시도를 확인한다.
- 스토어 심사 계정으로 첫 실행부터 배경 위치 기능까지 5분 내 재현 가능한지 검증한다.

### 릴리스 차단 기준

P0 차단:

- 사용자가 위치공유를 끄거나 탈퇴/차단/계정 삭제한 뒤에도 위치가 조회된다.
- 원시 위치, 주소, 전화번호, 초대 토큰, 아동 식별 정보가 분석/광고/크래시 로그로 전송된다.
- 광고 SDK로 정밀 위치, 배경 위치, 가족 관계, SOS 상태가 전달된다.
- SOS 발동/전달/취소 흐름에 치명 오류가 있거나 광고/권한 팝업이 SOS를 막는다.
- 배경 위치 권한 요청 전 앱 내 prominent disclosure가 없거나, 스토어 선언과 실제 동작이 다르다.
- App Privacy/Data Safety/개인정보 처리방침이 실제 SDK 수집 행위와 불일치한다.
- 미성년자/아동 사용자에게 개인화 광고 또는 광고 ID 전송이 발생한다.
- 계정 삭제/데이터 삭제가 앱 내에서 불가능하거나 서버에 반영되지 않는다.
- 양방향 동의 없이 초대받은 사용자의 위치가 노출된다.
- 위치 기록 삭제 후 재조회가 가능하다.

P1 차단:

- 정상 네트워크에서 위치 최신성 p95가 제품 목표를 지속적으로 초과한다.
- 지오펜스 알림 중복/누락이 베타 기준치를 초과한다.
- Android 주요 OEM에서 배경 위치가 설명 없이 장시간 중단된다.
- iOS/Android 최신 OS에서 위치/알림 권한 상태 변경 후 앱 UI가 잘못 표시된다.
- 광고 전면 노출이 주요 플로우 이탈 또는 접근성 문제를 유발한다.
- 지도 장애 시 핵심 상태 표시가 불가능하다.
- 크래시-free users, ANR, API 5xx, 푸시 실패율이 릴리스 목표를 넘는다.

P2 차단 또는 출시 후 즉시 수정:

- 권한 설명 문구가 모호하거나 스토어 설명과 표현이 다르다.
- 일부 화면에서 오래된 위치 표시가 충분히 눈에 띄지 않는다.
- 광고 빈도 제한/빈 광고 영역 처리의 UX 품질이 낮다.
- 로그 이벤트 누락으로 핵심 퍼널 분석이 어렵다.
- 접근성 라벨, 다크모드, 작은 화면 대응 이슈가 있다.

## 알려진 고위험 이슈와 완화책

| 고위험 이슈 | 영향 | 완화책 |
| --- | --- | --- |
| 배경 위치 심사 거절 | 출시 지연, 기능 축소 | 핵심 기능 하나를 명확히 선택하고, 앱 내 고지/스토어 설명/심사용 영상/테스트 계정을 일관되게 준비한다. 필요 없는 배경 위치 코드는 제거한다. |
| 아동 대상 앱의 위치/광고 정책 위반 | 앱 삭제, 계정 제재, 법적 리스크 | 보호자 중심 설계, 중립적 나이 확인, 보호자 동의, 아동/동의 미확인 사용자 광고 ID 차단, 법무 검토를 출시 조건으로 둔다. |
| 광고 수익화와 위치 데이터 결합 | 스토어 거절, 신뢰 하락, 규제 리스크 | 위치 데이터는 광고에 사용하지 않는다. 광고 SDK에 위치/가족/SOS 파라미터 전달을 네트워크 테스트로 차단 검증한다. |
| 숨은 추적/스토킹 악용 | 사용자 안전 침해, 평판 리스크 | 양방향 동의, 초대 만료, 공유 일시정지, 차단, 공유 중 표시, 탈퇴 즉시 차단, 비정상 조회 탐지, 신고 기능을 제공한다. |
| 배터리 과소모 | 삭제율 증가, OS 제한 | 이동 상태 기반 주기 조정, significant-change/geofence 우선, 정지 상태 저빈도, 저전력 감지, 배터리 대시보드를 운영한다. |
| 지오펜스 오탐/누락 | 안전 기능 신뢰 저하 | 정확도 반경 고려, dwell time, hysteresis, 중복 억제, 낮은 정확도 보류, 사용자별 반경 추천을 적용한다. |
| SOS 신뢰성 부족 | 가장 큰 제품 리스크 | 광고/결제/가입과 완전 분리, 우선순위 큐, 푸시 실패 재시도, 수신 확인, 오프라인 큐, 장애 알림을 구현한다. |
| 오래된 위치를 실시간처럼 표시 | 오해와 안전 문제 | 모든 위치에 최신성 라벨, 오래된 위치 색상/아이콘 분리, 갱신 실패 원인 안내를 제공한다. |
| 지도/푸시/광고 SDK 장애 전파 | 핵심 기능 장애 | 핵심 안전 기능과 광고 로딩을 분리하고, 지도 장애 시 목록/마지막 상태 fallback을 제공한다. |
| SDK가 정책 외 데이터를 자동 수집 | Data Safety/App Privacy 불일치 | SDK 버전 고정, 릴리스별 SDK 스캔, 프록시 트래픽 검사, SDK 개인정보 문서 보관, allowlist 외 SDK 금지. |
| 계정 삭제/데이터 삭제 불완전 | 스토어 거절, 법적 리스크 | 삭제 API를 제품 기능으로 구현하고, 백업/로그/분석 데이터의 삭제 또는 익명화 정책을 자동화한다. |
| 초대 링크 탈취/재사용 | 무단 위치 접근 | 초대 토큰 만료, 1회성 옵션, 그룹 관리자 취소, 수락 전 미리보기 제한, 비정상 수락 알림을 적용한다. |
| 위치 기록으로 생활 패턴 노출 | 민감정보 침해 | 기본 보관 기간 최소화, 기록 끄기, 특정 장소 마스킹, 기록 접근권한 세분화, 내보내기/삭제 감사 로그를 적용한다. |
| 플랫폼별 백그라운드 제한 차이 | Android OEM/iOS 버전별 품질 편차 | OEM/OS 매트릭스 베타, foreground service 알림, 사용자 친화적 상태 안내, 원격 설정으로 주기 조정. |
| 스토어 메타데이터와 실제 동작 불일치 | 심사 거절/업데이트 차단 | 릴리스 PR마다 권한/SDK/개인정보 라벨/Data Safety diff를 필수 검토 항목으로 둔다. |

## 최종 검수 산출물

- 기능 QA 결과표와 P0/P1/P2 결함 목록.
- iOS App Review Notes, Google Play Background Location 선언 문구, 심사용 영상 링크.
- App Privacy 라벨 초안, Google Play Data Safety 초안, 개인정보 처리방침 데이터 맵.
- 광고 SDK 데이터 수집 검증 리포트와 네트워크 프록시 로그 요약.
- 베타 테스트 리포트: 위치 최신성, SOS 전달률, 배터리, 크래시/ANR, 광고 오류, 권한 퍼널.
- 출시 승인 서명: QA, 개인정보/정책, 보안, 개발, 제품 책임자.
