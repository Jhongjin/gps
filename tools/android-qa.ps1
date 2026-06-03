param(
  [switch]$Install,
  [switch]$Launch,
  [switch]$Logcat
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$appDir = Join-Path $root 'apps/gyeote_flutter'
$apkPath = Join-Path $appDir 'build/app/outputs/flutter-apk/app-debug.apk'
$packageName = 'app.gyeote.gyeote'

. (Join-Path $PSScriptRoot 'flutter-env.ps1')
Initialize-GyeoteFlutterEnv -RepoRoot $root

Push-Location $appDir
try {
  flutter pub get
  flutter build apk --debug
}
finally {
  Pop-Location
}

$devices = adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\sdevice$' }
if (-not $devices) {
  Write-Host 'No Android device is connected. Enable USB debugging or start an emulator, then rerun this script.'
  Write-Host "APK is ready at: $apkPath"
  exit 0
}

if ($Install) {
  adb install -r $apkPath
}

if ($Launch) {
  adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1
}

if ($Logcat) {
  adb logcat -c
  adb logcat ActivityManager:I flutter:I GyeoteLocation:D AndroidRuntime:E '*:S'
}
