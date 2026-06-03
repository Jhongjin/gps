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
