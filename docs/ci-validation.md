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
