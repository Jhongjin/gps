# 곁에 스토어 등록 가이드 — Google Play · App Store

작성일: 2026-09-08. 이 문서는 **코드에서 확인한 사실**을 바탕으로 쓴다. 사람이 해야
하는 일과 이미 코드에 들어 있는 것을 갈라 적는다. `docs/store-review-pack.md` 의
심사 노트·백그라운드 위치 선언 초안은 그대로 쓴다.

일본은 출시 대상에서 **제외**한다(2026-09-08 결정). 두 스토어 모두 국가 선택에서
일본을 빼고, 일본어 로케일은 넣지 않는다.

---

## 0. 지금 상태 — 코드가 이미 갖춘 것 / 사람이 해야 하는 것

| 항목 | 상태 | 비고 |
|---|---|---|
| 앱 ID | ✅ `app.gyeote.gyeote` (Android·iOS 동일) | 스토어에 한 번 등록하면 못 바꾼다 |
| 버전 | `0.1.0+1` (`pubspec.yaml`) | 제출마다 `+N` 을 올린다 |
| 계정 삭제 (앱 안) | ✅ 안심 화면 → 내 데이터 → 계정 삭제 | 두 스토어의 필수 조건. 서버 함수 `delete_my_account` |
| 위치 기록 즉시 삭제 | ✅ 안심 화면 | 예전엔 요청만 쌓였고 처리되지 않았다 |
| 개인정보 처리방침 링크 (앱 안) | ✅ 안심 화면 하단 | 주소: `PRIVACY_POLICY_URL` (기본 `https://gyeote.app/privacy`) |
| 개인정보 처리방침 페이지 | 🟡 **파일 완성, 호스팅 필요** | `docs/site/privacy.html` (원문 `docs/privacy-policy.md`). 법률 검토 뒤 `gyeote.app/privacy` 에 올린다 |
| 계정 삭제 웹 페이지 | 🟡 **파일 완성, 호스팅 필요** | `docs/site/delete-account.html` → `gyeote.app/delete-account`. Google Play 데이터 안전 양식이 이 URL 을 요구한다 (§3-4) |
| 아이콘 | ✅ 생성됨 (`docs/store-assets/`) | 디자이너 작업으로 교체 권장. Flutter 기본 아이콘은 거절 사유 |
| Android 업로드 키 | ❌ **생성 필요** | `android/key.properties.example` 참고. 없으면 디버그 서명 → 거절 |
| iOS 서명·빌드 | 🟡 **파이프라인 준비됨, 연결 필요** | `codemagic.yaml` — 저장소를 Codemagic 에 연결하고 App Store Connect API 키와 환경변수 그룹만 채우면 Mac 러너가 TestFlight 까지 올린다. §2-2 |
| 백그라운드 위치 선언·영상 | 초안 있음 | `docs/store-review-pack.md` |
| 광고 SDK | 없음 (자리만) | 지금은 "광고 없음"으로 선언. AdMob 넣으면 데이터 안전·앱 개인정보 다시 |
| 프로덕션 DB | ❌ 마이그레이션 `012`–`020` 미적용 | `tools/apply-migrations.ps1`. 로컬 체인은 통과 |
| 지도 타일 | 🟡 **코드 완료, 키 필요** | `--dart-define=MAP_TILE_URL=…` / `MAP_TILE_ATTRIBUTION=…` 로 공급자를 끼운다. 기본값(OSM 공용)은 개발용. MapTiler·Stadia 등에서 키를 받아 넣는다. §5 |

---

## 1. 사전 준비 (양쪽 공통)

1. **개발자 계정**
   - Google Play Console: 1회 25달러. 개인 또는 조직. 조직은 D-U-N-S 번호가 필요하고,
     2023년 11월 이후 만든 **개인** 계정은 프로덕션 전에 클로즈드 테스트를 **테스터
     12명 이상, 14일 연속**으로 통과해야 한다. 회사 계정이면 이 조건이 없다.
   - Apple Developer Program: 연 99달러. 조직은 D-U-N-S 필요, 승인에 며칠.
2. **개인정보 처리방침 페이지** — `docs/privacy-policy.md` 를 법률 검토 뒤
   `https://gyeote.app/privacy` 에 게시. 앱과 두 스토어 양식에 같은 주소.
3. **계정 삭제 안내 페이지** — `https://gyeote.app/delete-account` 같은 주소에
   "앱 → 안심 → 계정 삭제" 절차와 이메일 요청 방법을 적는다. Google Play 데이터 안전
   양식이 URL 을 요구한다.
4. **지원 이메일·URL** — 두 스토어 모두 필수.
5. **테스트 계정 2개** — 서클을 하나 만들고 서로 초대를 수락해 둔 상태. 심사자가 두
   번째 계정 없이는 위치 공유를 볼 수 없다. 비밀번호는 심사 기간 동안 바꾸지 않는다.
6. **심사 영상** (Google Play 백그라운드 위치 필수, Apple 도 요구할 수 있음) —
   `docs/store-review-pack.md` 의 "Review Video Checklist" 순서대로 찍는다. 에뮬레이터
   화면 녹화: `adb shell screenrecord /sdcard/review.mp4`.
7. **프로덕션 DB** — `tools/apply-migrations.ps1` 로 비교 → `-Apply`. 그 전에
   `python tools/check_migrations_local.py` 가 통과해야 한다. **`018` 은 앱이 원시
   좌표를 더 이상 보내지 않는 빌드가 배포된 뒤에 적용**한다 — 이 저장소의 현재
   빌드가 그 빌드다.

---

## 2. 빌드 만들기

### 2-1. Android (이 PC 에서 가능)

```powershell
# 1) 업로드 키 (한 번만). 잃어버리지 않게 백업한다.
keytool -genkey -v -keystore apps\gyeote_flutter\android\upload-keystore.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2) android\key.properties.example 을 android\key.properties 로 복사해 채운다.

# 3) 버전 올리기: pubspec.yaml 의 version (예: 0.1.0+2)

# 4) 앱 번들 (Play 는 AAB 만 받는다)
cd apps\gyeote_flutter
flutter build appbundle --release `
  --dart-define=SUPABASE_URL=https://usetuwqbzkmywmtgwwdx.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key> `
  --dart-define=INVITE_BASE_URL=https://gyeote.app/invite `
  --dart-define=PRIVACY_POLICY_URL=https://gyeote.app/privacy
# → build\app\outputs\bundle\release\app-release.aab
```

확인: `apksigner verify --print-certs` 로 서명 주체가 디버그(`CN=Android Debug`)가
아닌지 본다. `key.properties` 가 없으면 빌드는 되지만 디버그 서명이고, Play 가 거절한다.

Play App Signing 을 켠다(기본). 업로드 키를 잃어도 Google 이 앱 서명 키를 갖고 있어
재설정할 수 있다.

### 2-2. iOS (Mac 이 필요하다)

이 저장소는 Windows 에서 작업했고 iOS 는 **한 번도 빌드된 적이 없다.** 순수 로직은
`tools/check_ios_logic.py` 로 검증했지만, Xcode 빌드·서명·TestFlight 는 Mac 에서만
된다. 선택지:

- Mac 실기(Mac mini 면 충분).
- 클라우드 Mac(MacStadium, MacInCloud) 시간제.
- CI 서비스(Codemagic, Bitrise): Windows 에서 push 하면 Mac 러너가 빌드·TestFlight
  업로드까지 한다. Flutter 지원이 좋고 처음 셋업이 가장 빠르다.

Mac 에서 할 일:
1. Xcode 설치, Apple ID 로그인, `ios/Runner.xcworkspace` 열기.
2. Runner 타깃 → Signing & Capabilities → Team 지정, "Automatically manage signing".
   Bundle ID `app.gyeote.gyeote` 는 developer.apple.com 에서 자동 등록된다.
3. Capabilities: **Background Modes → Location updates** 체크(Info.plist 의
   `UIBackgroundModes` 와 맞아야 한다). Push 는 지금 쓰지 않는다.
4. `ios/Runner/Info.plist` 에 `ITSAppUsesNonExemptEncryption` = `NO` 추가 —
   HTTPS 만 쓰므로 수출 규정 면제. 없으면 제출 때마다 묻는다.
5. 영어 권한 문구: `en.lproj/InfoPlist.strings` 를 만들어
   `NSLocationWhenInUseUsageDescription` 등 4개 키의 영어 문구를 넣는다. 현재
   Info.plist 는 한국어뿐이라 영어 심사자에게 한국어 다이얼로그가 보인다.
   (Xcode 에서 파일을 추가해야 pbxproj 에 등록된다 — Windows 에서 손으로 하지 않은 이유.)
6. `flutter build ipa --release --dart-define=...`(위와 같은 값) → Xcode Organizer 또는
   Transporter 로 업로드.
7. 처음엔 TestFlight 로 내부 테스터에게 배포해 실기기에서 백그라운드 위치·알림을 본다.

---

## 3. Google Play Console — 단계별

### 3-1. 앱 만들기
Play Console → 앱 만들기. 이름 "곁에", 기본 언어 한국어, 앱, 무료. 무료 → 유료는
나중에 못 바꾼다.

### 3-2. 대시보드 "앱 설정" 항목

1. **앱 액세스**: "일부 기능이 제한됨" → 테스트 계정 2개의 이메일·비밀번호와 "두
   계정은 이미 같은 서클에 있다"는 설명. 이걸 빼먹으면 심사자가 빈 화면만 본다.
2. **광고**: 현재 "앱에 광고 없음". AdMob 을 넣는 순간 "있음"으로 바꾸고 데이터
   안전도 다시 쓴다.
3. **콘텐츠 등급**: IARC 설문. 폭력·성적 내용 없음, 사용자 간 상호작용 있음(위치
   공유), 위치 공유 있음 → 보통 "전체이용가/Teen" 급.
4. **타겟층 및 콘텐츠**: 연령대에서 **13세 미만을 포함하지 않는다.** 곁에는 보호자가
   계정을 만들고 아동은 보호자 서클 안에서 공유되는 구조다. 13세 미만을 대상에 넣으면
   Families 정책(광고 SDK 인증, 데이터 제한)이 통째로 적용된다. "아동에게 매력적으로
   보일 수 있는 앱인가" 에는 아니오.
5. **뉴스 앱**: 아니오. **코로나 접촉 추적**: 아니오. **정부 앱**: 아니오.
   **금융 기능**: 아니오. **건강**: 아니오.
6. **데이터 안전** — §3-4.
7. **민감 권한·API 선언** — §3-5.

### 3-3. 스토어 등록정보
- 앱 이름 30자, 짧은 설명 80자, 전체 설명 4000자. 톤은 디자인 스킬 §1: 추적·감시가
  아니라 공유·확인·동의.
- 아이콘 512×512 PNG: `docs/store-assets/play-icon-512.png`.
- 그래픽 이미지 1024×500: 만들어야 한다.
- 스크린샷: 휴대전화 최소 2장(16:9 또는 9:16). 에뮬레이터에서
  `adb exec-out screencap -p > shot.png`. 지도·멤버 시트·안심 화면·약속 카드.
- 카테고리: 지도/내비게이션 또는 라이프스타일.
- 연락처 이메일, 개인정보 처리방침 URL.

### 3-4. 데이터 안전 양식 — 코드 기준 답

"수집 또는 공유하나요?" → 예. "암호화 전송" → 예. "사용자가 삭제 요청 가능" → 예,
URL 은 계정 삭제 안내 페이지.

| 데이터 유형 | 수집 | 공유 | 목적 | 필수/선택 |
|---|---|---|---|---|
| 위치 — 대략적 | 예 | 예 (서클 멤버) | 앱 기능 | 필수 |
| 위치 — 정확 | 예 | 예 (서클 멤버) | 앱 기능 | 필수 (사용자가 정확도 낮출 수 있음) |
| 개인 정보 — 이름 | 예 | 예 (서클 멤버) | 앱 기능 | 필수 |
| 개인 정보 — 이메일 | 예 | 아니오 | 계정 관리 | 필수 |
| 앱 활동 — 앱 내 상호작용 (확인 응답·열람 기록·약속) | 예 | 예 (서클 멤버) | 앱 기능 | 필수 |
| 기기 또는 기타 ID | 예 | 아니오 | 앱 기능 | 필수 |
| 앱 정보 및 성능 — 크래시 로그 | 아니오 | — | — | (SDK 없음) |
| 광고 ID | 아니오 | — | — | (SDK 없음) |

"공유"에 서클 멤버를 적는 이유: Google 의 정의에서 다른 사용자에게 보여 주는 것도
공유다. 처리 위탁(Supabase)은 "서비스 제공업체"라 공유로 세지 않는다.

**계정 삭제**: "계정 생성 허용" 예 → 삭제 URL 입력. 앱 안 삭제는 안심 화면에 있다.

### 3-5. 민감 권한 선언 (거절이 가장 잦은 곳)

1. **위치 (백그라운드)** — `ACCESS_BACKGROUND_LOCATION`. 선언문은
   `docs/store-review-pack.md` "Google Play Background Location Declaration Draft".
   핵심 기능(동행 모드·장소 알림)에 필요하다는 점, 앱 안에서 요청 전에 사전 고지
   화면이 있다는 점(온보딩 `permission_primer.dart`), 언제든 끌 수 있다는 점. **영상
   URL 필수** — 사전 고지 → 권한 요청 → 백그라운드에서도 동작하는 장면.
2. **포그라운드 서비스 유형 `location`** — 2024년부터 별도 선언. "사용자가 동행 모드나
   긴급 공유를 시작한 동안 위치를 수집하며, 알림으로 표시되고 사용자가 끝낸다."
   영상은 위 것과 같이 써도 된다.
3. 정확한 위치(`ACCESS_FINE_LOCATION`) 자체는 선언이 아니라 사용 사유 설명으로 충분.

### 3-6. 테스트 트랙 → 프로덕션
1. **내부 테스트**: AAB 업로드, 테스터 이메일 목록. 즉시 배포된다. 여기서 실기기로
   위젯 배치·30분 갱신·실제 지오펜스를 본다(에뮬레이터가 못 보는 셋).
2. **클로즈드 테스트**: 개인 계정이면 12명·14일 필수. 회사 계정도 한 번 거치는 편이
   좋다 — 백그라운드 위치가 OEM 마다 다르게 죽는다(`docs/qa.md` 고위험 표).
3. **프로덕션**: 국가 선택에서 **일본 제외**. 검토 제출. 첫 심사는 며칠에서 일주일,
   백그라운드 위치가 있으면 더 걸릴 수 있다.

---

## 4. App Store Connect — 단계별

### 4-1. 준비
Mac 에서 §2-2 를 끝낸 뒤. developer.apple.com → Certificates, Identifiers & Profiles 에서
Bundle ID `app.gyeote.gyeote` 가 보이는지 확인(Xcode 자동 서명이 만든다).

### 4-2. 앱 레코드
App Store Connect → 나의 앱 → + → 신규 앱. 플랫폼 iOS, 이름 "곁에", 기본 언어
한국어, Bundle ID 선택, SKU `gyeote-ios`.

### 4-3. 앱 정보
- 카테고리: 내비게이션 또는 라이프스타일. 보조: 유틸리티.
- 연령 등급: 설문에서 폭력·성적 내용 없음, "빈번한/강도 높은" 항목 없음,
  **무제한 웹 액세스 아니오**, 사용자 생성 콘텐츠·위치 공유 관련 질문에 정직하게 →
  보통 4+ 또는 12+.
- 개인정보 처리방침 URL.
- 콘텐츠 권한: 제3자 콘텐츠 없음(OSM 지도는 저작자 표시를 앱 안에 한다 —
  `MapAttribution`).

### 4-4. 앱 개인정보 (Nutrition Label) — 코드 기준 답

"데이터를 수집합니까?" → 예. 모든 항목 "사용자에게 연결됨" 예, "추적에 사용" **아니오**
(`NSUserTrackingUsageDescription` 없음, 광고 SDK 없음).

| 카테고리 | 항목 | 목적 |
|---|---|---|
| 위치 | 정확한 위치, 대략적 위치 | 앱 기능 |
| 연락처 정보 | 이름, 이메일 주소 | 앱 기능, 계정 관리 |
| 식별자 | 사용자 ID, 기기 ID | 앱 기능 |
| 사용 데이터 | 제품 상호작용 (확인 응답·열람 기록·약속) | 앱 기능 |
| 진단 | 없음 | — |

### 4-5. 버전 제출
- 스크린샷: 6.9"/6.7" 필수(iPhone), 6.5"·5.5" 는 자동 축소 허용. iPad 를 지원하면
  iPad 도. 시뮬레이터 스크린샷은 Mac 에서.
- 빌드 선택(TestFlight 에 올라온 것).
- **수출 규정**: HTTPS 만 → 면제. plist 에 `ITSAppUsesNonExemptEncryption=NO`.
- **심사 정보**: 데모 계정 이메일·비밀번호(테스트 계정 1), 연락처. **노트**에
  `docs/store-review-pack.md` "Apple App Review Notes Draft" 를 붙이고, 아래 두 줄을
  더한다:
  - "Account deletion is available in-app: 안심(Privacy) → 내 데이터 → 계정 삭제."
  - "Background location is used only while the user has started Companion Mode or
    enabled a Place Alert; the app never uses it for ads."
- 출시 국가: **일본 제외**.
- 심사는 보통 24–48시간. 백그라운드 위치와 계정 삭제는 심사자가 직접 눌러 본다.

### 4-6. 지침에서 곁에가 걸리는 조항
- **5.1.1(v) 계정 삭제** — 앱 안 구현 완료. 삭제 뒤 로그인 화면으로 돌아가야 한다.
- **5.1.1 데이터 최소화 / 5.1.2 사용** — 위치를 광고에 쓰지 않는다는 문장을 노트와
  처리방침 양쪽에.
- **2.5.4 백그라운드 모드** — 위치 백그라운드는 "사용자에게 보이는 기능"에만. 동행 모드
  중 iOS 파란 상태 표시줄이 뜨는 것이 그 증거다.
- **5.1.5 위치 서비스** — 사용 사유 문구가 정확해야 한다(현재 plist 문구는 맞다).
- **1.3 아동** — 아동 대상 앱으로 등록하지 않는다. 처리방침 §6 과 맞춘다.

---

## 5. 거절이 잦은 자리와 미리 막는 법

| 위험 | 막는 법 |
|---|---|
| 백그라운드 위치 근거 부족 | 영상에 사전 고지 → 권한 → 백그라운드 동작 → 끄기 순서를 다 담는다 |
| 데모 계정 로그인 실패 | 제출 직전에 두 계정으로 실제 로그인·서클 확인 |
| 계정 삭제 미제공 | 이제 있다. 심사 노트에 경로를 적는다 |
| 처리방침·데이터 양식 불일치 | 이 문서 §3-4·§4-4 표와 `docs/privacy-policy.md` 를 같은 날 고친다 |
| 광고 SDK 추가 뒤 양식 미갱신 | AdMob 을 넣는 PR 에 데이터 안전·앱 개인정보 변경을 필수 항목으로 |
| 디버그 서명 AAB | `key.properties` 없이 빌드하지 않는다 |
| Flutter 기본 아이콘 | 교체됨. 디자이너 아이콘으로 다시 교체 권장 |
| OSM 공용 타일 | 빌드에 유료 타일을 넣는다. 예 (MapTiler): `--dart-define=MAP_TILE_URL="https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=KEY" --dart-define=MAP_TILE_ATTRIBUTION="© MapTiler © OpenStreetMap contributors"`. 표시 문구는 공급자가 정해 준 것을 쓴다. OSM 정책은 앱 규모 트래픽을 막고, 타일 요청에 IP 가 실린다는 사실을 처리방침에 적었다 |
| 일본어 화면 없음 | 일본 제외로 해결. 국가 목록에서 빼는 것을 잊지 않는다 |

---

## 6. 제출 직전 체크리스트

- [ ] `python tools/check_migrations_local.py` 통과 후 `tools/apply-migrations.ps1 -Apply`
- [ ] `pubspec.yaml` 버전 올림
- [ ] Android: `key.properties` 존재, `flutter build appbundle --release --dart-define=...`
- [ ] iOS (Mac): Team·Background Modes·`ITSAppUsesNonExemptEncryption`·영어 InfoPlist 문구, `flutter build ipa`
- [ ] 처리방침·계정 삭제 페이지가 실제로 열린다 (앱의 안심 화면 링크로 확인)
- [ ] 테스트 계정 2개 로그인 확인, 같은 서클
- [ ] 심사 영상 URL
- [ ] 데이터 안전 / 앱 개인정보 양식이 §3-4 / §4-4 표와 같다
- [ ] 국가 목록에서 일본 제외
- [ ] `pwsh tools/android-emulator-check.ps1` 통과 (부팅·위젯·실제 지오펜스)
- [ ] 실기기 1대에서 위젯 배치·30분 갱신 확인 (내부 테스트 트랙)
