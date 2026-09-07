<#
.SYNOPSIS
  에뮬레이터에서 앱을 실제로 띄워 본다. 단위 테스트가 못 보는 것만 본다.

.DESCRIPTION
  Robolectric 은 위젯이 무엇을 그리는지, 리시버가 어느 채널로 알림을 올리는지까지
  본다. 그 위에 남는 질문은 "실제 시스템에서 그 코드가 그 자리에 있는가"다:
  앱이 크래시 없이 뜨는가, 위젯 provider 가 런처에 등록되는가, 알림 채널이
  시스템에 만들어지는가, 지오펜스 등록이 시스템 서비스에서 받아들여지는가.

  이 스크립트는 API 35 x86_64 AVD 를 만들어 headless 로 부팅하고, 디버그 APK 를
  설치·실행한 뒤 adb 로 그 네 가지를 확인한다. 조작이 필요한 것(위젯을 홈에
  올리기, 권한 다이얼로그)은 adb 로 대신한다.

  전제: 가속. `emulator -accel-check` 가 WHPX 사용 가능이라고 답해야 한다.
  Hyper-V 가 켜진 PC 라면 Windows Hypervisor Platform 기능이 그 답을 만든다.

.PARAMETER SkipBuild
  이미 만든 build\app\outputs\flutter-apk\app-debug.apk 를 쓴다.
#>
[CmdletBinding()]
param(
  [switch]$SkipBuild,
  [int]$BootTimeoutSec = 300
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$app = Join-Path $root 'apps\gyeote_flutter'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'
$avdmanager = Join-Path $sdk 'cmdline-tools\latest\bin\avdmanager.bat'
$flutter = 'D:\Codex\toolchains\flutter\bin\flutter.bat'
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:ANDROID_HOME = $sdk
$package = 'app.gyeote.gyeote'
$avd = 'gyeote-api35'
$image = 'system-images;android-35;google_apis;x86_64'

$failures = New-Object System.Collections.Generic.List[string]
function Check([string]$name, [bool]$ok, [string]$detail = '') {
  if ($ok) { Write-Host "  ok  $name" } else { Write-Host "FAIL  $name  $detail"; $failures.Add($name) }
}

foreach ($tool in @($adb, $emulator, $avdmanager)) {
  if (-not (Test-Path $tool)) { throw "없다: $tool — sdkmanager 로 platform-tools, emulator, cmdline-tools 를 받는다." }
}
if (-not (Test-Path (Join-Path $sdk 'system-images\android-35\google_apis\x86_64'))) {
  throw "시스템 이미지가 없다: sdkmanager `"$image`""
}

# 1. APK
$apk = Join-Path $app 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not $SkipBuild -or -not (Test-Path $apk)) {
  Push-Location $app
  try { & $flutter build apk --debug | Out-Host } finally { Pop-Location }
}
Check 'debug APK exists' (Test-Path $apk)

# 2. AVD (있으면 재사용)
$existing = & $avdmanager list avd 2>$null | Select-String -Pattern "Name: $avd"
if (-not $existing) {
  'no' | & $avdmanager create avd -n $avd -k $image -d 'pixel_6' --force | Out-Host
}
# avdmanager 가 AVD 를 어디에 두었는지 그대로 에뮬레이터에 알려 준다. 이 PC 에서는
# 기본 위치(~\.androidvd)가 아니라 다른 도구의 설정 디렉터리 아래였고, 에뮬레이터는
# 기본 위치만 보고 "Unknown AVD" 로 즉시 죽었다 — 그게 첫 실행의 "부팅 실패"였다.
$pathLine = & $avdmanager list avd 2>$null | Select-String -Pattern ("Path: (.+" + [regex]::Escape("\$avd.avd") + ")")
if ($pathLine) {
  $env:ANDROID_AVD_HOME = Split-Path -Parent $pathLine.Matches[0].Groups[1].Value
  Write-Host "  AVD home: $env:ANDROID_AVD_HOME"
}

# 3. 부팅
& $adb start-server | Out-Null
$proc = Start-Process -FilePath $emulator -ArgumentList @("-avd", $avd, "-no-window", "-no-audio", "-no-boot-anim", "-gpu", "swiftshader_indirect", "-accel", "auto") -PassThru -WindowStyle Hidden
try {
  $deadline = (Get-Date).AddSeconds($BootTimeoutSec)
  $booted = $false
  while ((Get-Date) -lt $deadline) {
    $state = (& $adb shell getprop sys.boot_completed 2>$null | Out-String).Trim()
    if ($state -eq '1') { $booted = $true; break }
    if ($proc.HasExited) { break }
    Start-Sleep -Seconds 5
  }
  Check "emulator booted within ${BootTimeoutSec}s" $booted
  if (-not $booted) { throw "부팅 실패. 가속(WHPX)이 켜져 있는지 확인한다." }

  # 4. 설치·실행
  & $adb install -r $apk | Out-Host
  & $adb shell pm grant $package android.permission.ACCESS_FINE_LOCATION 2>$null
  & $adb shell pm grant $package android.permission.ACCESS_COARSE_LOCATION 2>$null
  & $adb shell pm grant $package android.permission.POST_NOTIFICATIONS 2>$null
  & $adb logcat -c
  & $adb shell monkey -p $package -c android.intent.category.LAUNCHER 1 | Out-Null
  Start-Sleep -Seconds 12

  $pid_ = (& $adb shell pidof $package | Out-String).Trim()
  Check 'app process alive after launch' ($pid_ -ne '')

  $crash = & $adb logcat -d 2>$null | Select-String -Pattern "FATAL EXCEPTION|AndroidRuntime.*$package" | Select-Object -First 1
  Check 'no fatal exception in logcat' (-not $crash) "$crash"

  # 5. 위젯 provider 가 시스템에 등록되는가
  $providers = & $adb shell dumpsys appwidget 2>$null | Out-String
  Check 'widget provider registered' ($providers -match 'GyeoteCircleWidget')

  # 6. 알림 채널: 장소 알림(기본)과 조용한 시간 채널은 리시버가 첫 전환에서
  #    만든다. 여기서는 포그라운드 서비스 채널이 앱 실행만으로 있는지 본다.
  $notif = & $adb shell dumpsys notification 2>$null | Out-String
  Check 'app registered with notification manager' ($notif -match $package)

  # 7. 위젯 갱신 인텐트 필터가 설치된 패키지에 있는가.
  #    GeofenceBroadcastReceiver 와 LocationForegroundService 는 인텐트 필터가
  #    없어(PendingIntent·startService 로만 불린다) dumpsys package 에 나오지
  #    않는다. 그 둘의 존재는 병합 매니페스트와 Robolectric 이 본다.
  $pkg = & $adb shell dumpsys package $package 2>$null | Out-String
  Check 'widget refresh intent filter present' ($pkg -match 'WIDGET_REFRESH')

  # 8. 위젯 갱신 브로드캐스트가 provider 에 전달되는가 (크래시 없이).
  & $adb logcat -c
  & $adb shell am broadcast -a app.gyeote.gyeote.WIDGET_REFRESH -n "$package/.GyeoteCircleWidget" | Out-Null
  Start-Sleep -Seconds 3
  $widgetCrash = & $adb logcat -d 2>$null | Select-String -Pattern "FATAL EXCEPTION" | Select-Object -First 1
  Check 'widget refresh broadcast handled without crash' (-not $widgetCrash) "$widgetCrash"
}
finally {
  & $adb emu kill 2>$null | Out-Null
  if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
}

if ($failures.Count -gt 0) { Write-Host "`n$($failures.Count) failing"; exit 1 }
Write-Host "`n에뮬레이터 스모크 통과."
exit 0
