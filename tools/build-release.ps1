<#
.SYNOPSIS
  스토어에 올릴 빌드를 만든다. Android AAB(기본), 또는 -Target apk / web.

.DESCRIPTION
  tools\release.env.ps1 (gitignore) 에서 Supabase·타일·URL 값을 읽어 --dart-define 으로
  넣는다. 값이 비어 있으면 멈춘다 — 빈 값으로 만든 빌드는 데모 모드로 떠서 스토어
  심사자가 빈 화면을 본다. Android 는 android\key.properties 가 있어야 업로드 키로
  서명된다; 없으면 디버그 서명이라 Play 가 거절하므로 역시 멈춘다.

  끝나면 서명 주체를 출력한다. "CN=Android Debug" 가 보이면 잘못된 빌드다.
#>
param(
  [ValidateSet('appbundle', 'apk', 'web')] [string]$Target = 'appbundle'
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$app = Join-Path $root 'apps\gyeote_flutter'
$envFile = Join-Path $root 'tools\release.env.ps1'
$flutter = 'D:\Codex\toolchains\flutter\bin\flutter.bat'

if (-not (Test-Path $envFile)) { throw "없다: $envFile — tools\release.env.example.ps1 을 복사해 채운다." }
. $envFile

$required = 'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'INVITE_BASE_URL', 'PRIVACY_POLICY_URL', 'MAP_TILE_URL', 'MAP_TILE_ATTRIBUTION'
foreach ($name in $required) {
  $value = [Environment]::GetEnvironmentVariable($name)
  if (-not $value -or $value -like '*<*') { throw "release.env.ps1 의 $name 이 비어 있거나 자리표시자다." }
}
if ($env:MAP_TILE_URL -like '*tile.openstreetmap.org*') { throw "MAP_TILE_URL 이 OSM 공용 서버다. 출시 빌드에는 유료 타일을 넣는다 (스토어 가이드 §5)." }
if ($Target -ne 'web' -and -not (Test-Path (Join-Path $app 'android\key.properties'))) {
  throw "android\key.properties 가 없다. 업로드 키 없이 만든 빌드는 디버그 서명이라 Play 가 거절한다."
}

# PowerShell 7 이 .bat 에 인자를 넘길 때 `{z}` 같은 중괄호와 공백이 든 값을 다시
# 인용하면서 flutter 가 자기 경로를 명령으로 받는 일이 있었다. cmd 에 한 줄로 넘긴다.
$defines = @(
  "SUPABASE_URL=$env:SUPABASE_URL",
  "SUPABASE_PUBLISHABLE_KEY=$env:SUPABASE_PUBLISHABLE_KEY",
  "INVITE_BASE_URL=$env:INVITE_BASE_URL",
  "PRIVACY_POLICY_URL=$env:PRIVACY_POLICY_URL",
  "MAP_TILE_URL=$env:MAP_TILE_URL",
  "MAP_TILE_ATTRIBUTION=$env:MAP_TILE_ATTRIBUTION"
) | ForEach-Object { '"--dart-define=' + $_ + '"' }
$commandLine = "`"$flutter`" build $Target --release " + ($defines -join ' ')

Push-Location $app
try {
  cmd /c $commandLine
  if ($LASTEXITCODE -ne 0) { throw "flutter build $Target 실패" }

  if ($Target -eq 'appbundle') {
    $out = 'build\app\outputs\bundle\release\app-release.aab'
    $jarsigner = 'C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe'
    $cert = & $jarsigner -verify -verbose -certs $out 2>&1 | Select-String 'CN=' | Select-Object -First 1
    Write-Host "산출물: $out"
    Write-Host "서명: $cert"
    if ("$cert" -like '*Android Debug*') { throw "디버그 서명이다. key.properties 를 확인한다." }
  } elseif ($Target -eq 'apk') {
    Write-Host '산출물: build\app\outputs\flutter-apk\app-release.apk'
  } else {
    Write-Host '산출물: build\web'
  }
} finally { Pop-Location }
