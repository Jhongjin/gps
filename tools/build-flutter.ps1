param(
  [ValidateSet('web', 'android-debug')]
  [string]$Target = 'web'
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$envFile = Join-Path $root '.env.local'
$appDir = Join-Path $root 'apps/gyeote_flutter'

. (Join-Path $PSScriptRoot 'flutter-env.ps1')
Initialize-GyeoteFlutterEnv -RepoRoot $root

$values = Get-GyeoteDotEnv -EnvFile $envFile -RequiredKeys @('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY')
$dartDefines = Get-GyeoteDartDefineArgs -Values $values

Push-Location $appDir
try {
  flutter pub get

  switch ($Target) {
    'web' {
      flutter @(@('build', 'web') + $dartDefines)
    }
    'android-debug' {
      flutter @(@('build', 'apk', '--debug') + $dartDefines)
    }
  }
}
finally {
  Pop-Location
}
