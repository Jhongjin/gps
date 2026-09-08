# tools\release.env.ps1 로 복사해 채운다. 그 파일은 .gitignore 에 있다 — 키를 저장소에
# 넣지 않는다. build-release.ps1 이 이 값을 --dart-define 으로 빌드에 넣는다.

$env:SUPABASE_URL             = "https://<project-ref>.supabase.co"
$env:SUPABASE_PUBLISHABLE_KEY = "<publishable key — Supabase 대시보드 → Settings → API>"
$env:INVITE_BASE_URL          = "https://gyeote.app/invite"
$env:PRIVACY_POLICY_URL       = "https://gyeote.app/privacy"

# 지도 타일. 개발 기본값(OSM 공용)은 출시용이 아니다. 예: MapTiler
$env:MAP_TILE_URL             = "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=<key>"
$env:MAP_TILE_ATTRIBUTION     = "© MapTiler © OpenStreetMap contributors"
