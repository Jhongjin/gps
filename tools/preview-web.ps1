<#
.SYNOPSIS
  앱 UI 를 PC 브라우저에서 본다. 웹 릴리스 빌드 → 로컬 서버 → 브라우저.

.DESCRIPTION
  Supabase 를 붙이지 않은 데모 모드다: 서울 강남 근처의 데모 멤버 넷, 약속·확인·
  열람 기록 등은 데모 데이터로 보인다. 기기 위치·권한·위젯·지오펜스처럼
  네이티브가 필요한 것은 "Android/iOS 빌드에서 연결됩니다"로 표시된다.

  PC 에서 실제 폰 비율로 보려면 브라우저 개발자 도구(F12) → 기기 툴바(Ctrl+Shift+M)
  → 아무 폰이나 고른다.

.PARAMETER SkipBuild
  build\web 이 이미 있으면 빌드를 건너뛴다.
.PARAMETER Port
  기본 4174.
#>
param(
  [switch]$SkipBuild,
  [int]$Port = 4174
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$app = Join-Path $root 'apps\gyeote_flutter'
$web = Join-Path $app 'build\web'
$flutter = 'D:\Codex\toolchains\flutter\bin\flutter.bat'

if (-not $SkipBuild -or -not (Test-Path (Join-Path $web 'index.html'))) {
  Push-Location $app
  try { & $flutter build web --release --pwa-strategy=none | Out-Host } finally { Pop-Location }
}

$url = "http://127.0.0.1:$Port/?v=$([DateTimeOffset]::Now.ToUnixTimeSeconds())"
Write-Host "여는 중: $url  (끝내려면 Ctrl+C)"
Start-Process $url
& (Join-Path $root 'tools\serve-prototype.ps1') -Root $web -Port $Port
