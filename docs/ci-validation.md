# CI 검증 계획

Date: 2026-05-30

현재 로컬 작업 환경은 bundled Flutter/Android toolchain으로 앱 검증이 가능하다. `psql`과 `supabase` CLI는 아직 없어 DB 적용 검증은 GitHub Actions 또는 Supabase SQL Editor 기준으로 둔다.

최근 로컬 검증 범위:

- `flutter analyze`
- `flutter test`
- `tools/build-flutter.ps1 -Target web`
- `tools/build-flutter.ps1 -Target android-debug`

## 추가된 워크플로

`.github/workflows/validate.yml`

검증 항목:

- Flutter dependency install
- `flutter analyze`
- `flutter test`
- JSON 파싱
- 구식 이름/깨진 인코딩 검색
- 이모지 UI 회귀 검색
- Supabase CLI 로컬 DB reset으로 migration 적용

## 첫 CI 통과 전 확인할 것

- Supabase CLI action이 현재 프로젝트 구조에서 `supabase/` 폴더를 정상 인식하는지.
- Flutter stable이 `sdk: ">=3.6.0 <4.0.0"` 제약과 맞는지.
- `supabase_flutter: ^2.12.2`가 현재 Flutter stable에서 정상 resolve되는지.
- Supabase local stack 시간이 길면 DB job timeout을 늘릴지.

## CI 실패 시 우선순위

1. Supabase migration 문법 오류.
2. Flutter analyzer 오류.
3. package version conflict.
4. 정적 검색의 false positive.

## 안드로이드 네이티브 검증 (2026-09-06 추가)

홈 위젯은 Dart 가 아니라 Kotlin + RemoteViews 라서 `flutter test` 가 한 줄도
지나가지 않는다. 에뮬레이터 없이 JVM 에서 확인한다.

```
JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"
cd apps/gyeote_flutter/android
./gradlew :app:testDebugUnitTest
```

- `GyeoteWidgetSnapshotTest` (8) — 스냅샷 모델. 좌표를 받지 않는다는 것,
  세 명 상한, 신선도 판정.
- `GyeoteCircleWidgetRenderTest` (6, Robolectric) — `buildViews` 가 실제로
  그린 뷰 트리를 읽는다. 사용자가 홈 화면에서 보는 글자가 여기서 결정된다.

### 이 환경에서 걸렸던 것

- **Robolectric 4.14.1 + JBR 25**: 계측기가 쓰는 ASM 9.7 이 클래스 파일
  major 69(Java 25)를 못 읽어 전 케이스가 `Unsupported class file major
  version 69` 로 죽는다. 이 워크스테이션의 유일한 JDK 가 JBR 25 라 JDK 를
  내리는 대신 Robolectric 4.16.1 + ASM 9.10.1 로 올렸다.
- **Kotlin 증분 컴파일 + JBR 25**: release 빌드가
  `Could not close incremental caches` 로 실패한다. `kotlin.incremental=false`
  로 껐다. 이 프로젝트 Kotlin 소스는 위젯 몇 개뿐이라 손해가 없다.
- **`packageDebugUnitTestForUnitTest`**: Flutter Gradle 플러그인이
  `copyFlutterAssets` 의존을 선언하지 않아 Gradle 9 검증이 막는다.
  `app/build.gradle.kts` 에서 명시한다.

### release APK 에서 확인한 것

`flutter build apk --release` 는 R8 + 리소스 축소를 켠다. 위젯은 매니페스트
에서만 참조되므로 축소에 특히 약하다. 빌드 후 확인:

- 매니페스트에 `GyeoteCircleWidget` 과 `WIDGET_REFRESH` 필터가 남는다.
- `classes.dex` 에 위젯 클래스가 있다 (`GyeoteWidgetSnapshot` 은 R8 이
  인라인해서 이름이 사라지는 것이 정상이다).
- `resources.arsc` 에 `widget_circle_info`, `widget_background`,
  `widget_dot_*`, 위젯 문자열이 모두 남는다.
  `mapping/release/resources.txt` 에 제거된 widget 리소스가 없어야 한다.

## iOS 순수 로직 검증 (2026-09-07 추가)

이 워크스페이스는 Windows 라 iOS 앱을 빌드할 수 없다. 그래서 iOS 네이티브를
"소스만 있고 검증 없음"으로 두면, 안드로이드에서만 가려지고 iOS 에서는 정확한
좌표가 그대로 나가는 식의 플랫폼 간 결함이 조용히 생긴다. 실제로 그랬다 —
`018` 이 원시 좌표 칸을 없앤 뒤에도 iOS `rowFromPayload` 는 `raw_lat`/`raw_lng`
를 보내고 있어서, 마이그레이션이 적용되는 순간 iOS 업로드가 전부 거절될
상태였다.

`AppDelegate.swift` 끝의 `GyeotePortable` 구역은 Foundation 만 쓴다(민감 장소
가림, 조용한 시간 창, 알림 문구). `tools/check_ios_logic.py` 가 그 구역을 잘라내
`tools/ios_logic_tests.swift` 와 함께 컴파일하고 실행한다. **컴파일되는 것은
배포되는 바로 그 코드다.** 새 파일로 빼지 않는 이유는 pbxproj 등록이 필요해서다
— Xcode 없이 손으로 만지면 프로젝트가 깨진다. 같은 이유로 알림 문구도
Localizable.strings 대신 코드 안의 표(`GyeoteNativeStrings`)에 둔다. 키는
안드로이드 `res/values/strings.xml` 과 같다.

```
python tools/check_ios_logic.py
```

이 PC 에서 돌리려면:

- `winget install Swift.Toolchain` (6.3.3)
- `winget install Microsoft.VisualStudio.2022.BuildTools` + `VC.Tools.x86.x64`
  + `Windows11SDK.22621` — Swift for Windows 는 `errno.h` 같은 UCRT 헤더를
  여기서 가져온다. 없으면 `import Foundation` 부터 실패한다.

스크립트는 툴체인 경로에서 런타임 DLL 경로와 `SDKROOT` 를 스스로 만든다. 설치기가
사용자 환경변수에 넣어 두지만 이미 떠 있던 셸은 그걸 모른다.

CI 는 `swift-actions/setup-swift` 로 Linux Swift 를 깔고 같은 스크립트를 돌린다.
툴체인이 없으면 건너뛰지 않고 실패한다 — 검증 없음을 통과로 세지 않는다.

검사가 실제로 잡는지 확인한 방법: 자정을 넘는 창의 `||` 를 `&&` 로 바꿔 보면
야간 창 케이스 세 개가 실패한다.

## 마이그레이션 체인 로컬 검증 (2026-09-07 추가)

```
python tools/check_migrations_local.py
```

Docker 없이 돈다. 포터블 PostgreSQL(`D:/Codex/toolchains/postgres/pgsql`, EDB
바이너리 zip)로 임시 클러스터를 `initdb` 해 띄우고, Supabase 전제
(`auth.uid()`, `auth.users` 의 id·aud·role·email·raw_user_meta_data, 세 역할,
public 스키마 기본 권한, pgcrypto)를 shim 으로 넣은 뒤 `001`→`019` 를 순서대로
적용한다. 이어서 `verification_after_*.sql` 열 개와 `negative_tests_after_*.sql`
여섯 개(40개 단언)를 돌린다. 부정 테스트는 마지막에
`bool_and(passed) | {단언: 통과} | {단언: 상세}` 한 줄을 내고, 러너는 첫 칸이
`t` 가 아니면 실패시킨다 — 처음엔 둘째 칸을 보고 있어서 깨진 단언을 통과로
셌다. 단언 하나를 일부러 틀리게 바꿔 실패하는 것을 확인했다.

이 검사가 처음 돌면서 잡은 것:

- **`016_quick_reply_statuses.sql` 이 009 를 베껴 010 을 되돌리고 있었다.**
  010 이 넣은 세션 소유권 검사(`companion_session_subject_required`)가 사라지고,
  반환 칼럼 `id` 와 겹치는 `where id = ...` 로 함수가 컴파일조차 안 됐다.
  016 은 010 본문 위에 세 가지 변경만 얹도록 다시 썼다.
- `014` 의 입력 인자 `quiet_hours` 가 반환 칼럼과 겹쳐 컴파일 실패.
  `new_quiet_hours` 로 바꾸고 Dart 호출부도 맞췄다.
- `015` 의 `on conflict (place_alert_id, ...)` 가 반환 칼럼과 모호. 함수에
  `#variable_conflict use_column` 을 줬다.
- `019` 의 반환 칼럼 `precision` 은 타입 키워드라 문법 오류. `viewed_precision`.
- 부정 테스트 픽스처 셋이 애초에 실행 불가였다: `location_source` 에 없는
  `'companion'`, 018 이후 없는 `raw_lat`, 서클 밖 사용자 역할로 RLS 에 가려진
  행의 id 를 조회해 `place_alert_not_found` 를 받던 두 곳(012·015).

프로덕션에 이미 올라간 `007`~`011` 은 손대지 않았다. 문제는 전부 **아직 올리지
않은** 파일에 있었고, 그래서 로컬 체인이 있기 전엔 보이지 않았다.

이 PC 특유의 함정: `pg_ctl start` 를 `capture_output` 으로 부르면 서버가 stdout
파이프를 물고 있어 영원히 선다(러너는 start/stop 만 파이프를 끊는다).
`LC_ALL=C` 를 주면 initdb 가 조용히 실패한다. 한국어가 든 SQL 을 `-c` 인자로
넘기면 콘솔 코드페이지로 깨진다(파일로 넘긴다). postgres.exe 가 간헐적으로
fail-fast(0xC0000409)로 죽어 initdb/start 에 재시도를 뒀다 — VS Build Tools
설치 뒤 재시작이 보류된 상태에서 봤다.

## 에뮬레이터 스모크 (2026-09-08 추가)

```
pwsh tools/android-emulator-check.ps1            # APK 빌드 포함
pwsh tools/android-emulator-check.ps1 -SkipBuild
```

API 35 x86_64 AVD(`gyeote-api35`)를 headless 로 띄워 디버그 APK 를 설치·실행하고
adb 로 본다: 프로세스 생존, FATAL EXCEPTION 없음, **위젯 provider 가 시스템
AppWidget 서비스에 등록됨**, 알림 관리자에 패키지 등록, WIDGET_REFRESH 인텐트
필터 존재, 그 브로드캐스트를 provider 가 크래시 없이 처리. 이 PC 에서는 WHPX
가속으로 30초 안에 부팅한다.

이 PC 의 함정: `avdmanager` 가 AVD 를 `~\.androidvd` 가 아니라
`D:\AI\opencode-data\config\.androidvd` 에 만든다(다른 도구의 설정 루트).
에뮬레이터는 기본 위치만 보고 "Unknown AVD" 로 즉시 죽는데, 스크립트는 그걸
"부팅 실패"로만 보여 줬다. 지금은 `avdmanager list avd` 의 Path 를 읽어
`ANDROID_AVD_HOME` 을 맞춘다.

이걸로도 못 보는 것: 실제 지오펜스 전환의 도착(Play Services 가 만드는 이벤트라
가짜로 넣을 수 없다), 30분 주기 위젯 갱신, 사용자가 위젯을 홈에 올리는 순간.
그 셋은 실기기에서 손으로 본다.

준비물(sdkmanager): `cmdline-tools;latest`, `platform-tools`, `emulator`,
`system-images;android-35;google_apis;x86_64`(약 1.2GB).
