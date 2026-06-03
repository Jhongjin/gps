$ErrorActionPreference = 'Stop'

function Add-GyeotePath {
  param([Parameter(Mandatory = $true)][string]$PathToAdd)

  if (-not (Test-Path -LiteralPath $PathToAdd)) {
    return
  }

  $parts = $env:Path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  if ($parts -notcontains $PathToAdd) {
    $env:Path = "$PathToAdd;$env:Path"
  }
}

function Initialize-GyeoteFlutterEnv {
  param([Parameter(Mandatory = $true)][string]$RepoRoot)

  $workspaceRoot = Split-Path -Parent $RepoRoot
  $flutterBin = Join-Path $workspaceRoot 'toolchains/flutter/bin'
  $androidSdk = Join-Path $workspaceRoot 'android-sdk'
  $pubCache = Join-Path $workspaceRoot 'pub-cache'

  New-Item -ItemType Directory -Force -Path $pubCache | Out-Null
  $env:PUB_CACHE = $pubCache

  Add-GyeotePath $flutterBin
  Add-GyeotePath 'C:\Program Files\Git\cmd'
  Add-GyeotePath 'C:\Windows\System32\WindowsPowerShell\v1.0'

  if (Test-Path -LiteralPath $androidSdk) {
    $env:ANDROID_HOME = $androidSdk
    $env:ANDROID_SDK_ROOT = $androidSdk
    Add-GyeotePath (Join-Path $androidSdk 'platform-tools')
    Add-GyeotePath (Join-Path $androidSdk 'cmdline-tools/latest/bin')
  }

  $jdkRoot = Get-ChildItem -Path 'C:\Program Files\Microsoft' -Directory -Filter 'jdk-21*hotspot' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if ($jdkRoot) {
    $env:JAVA_HOME = $jdkRoot.FullName
    Add-GyeotePath (Join-Path $jdkRoot.FullName 'bin')
  }

  if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter was not found. Expected local SDK at $flutterBin."
  }
}

function Get-GyeoteDotEnv {
  param(
    [Parameter(Mandatory = $true)][string]$EnvFile,
    [string[]]$RequiredKeys = @()
  )

  if (-not (Test-Path -LiteralPath $EnvFile)) {
    throw '.env.local is missing. Create it from .env.example before running Flutter.'
  }

  $values = @{}
  Get-Content -LiteralPath $EnvFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) {
      return
    }

    $parts = $line.Split('=', 2)
    if ($parts.Count -eq 2) {
      $values[$parts[0].Trim()] = $parts[1].Trim()
    }
  }

  foreach ($key in $RequiredKeys) {
    if (-not $values.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($values[$key])) {
      throw "$key is missing from .env.local."
    }
  }

  return $values
}

function Get-GyeoteDartDefineArgs {
  param([Parameter(Mandatory = $true)][hashtable]$Values)

  $inviteBaseUrl = if ($Values.ContainsKey('INVITE_BASE_URL')) { $Values['INVITE_BASE_URL'] } else { 'https://gyeote.app/invite' }

  return @(
    "--dart-define=SUPABASE_URL=$($Values['SUPABASE_URL'])",
    "--dart-define=SUPABASE_PUBLISHABLE_KEY=$($Values['SUPABASE_PUBLISHABLE_KEY'])",
    "--dart-define=INVITE_BASE_URL=$inviteBaseUrl"
  )
}
