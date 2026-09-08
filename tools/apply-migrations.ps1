<#
.SYNOPSIS
  프로덕션 Supabase 에 미적용 마이그레이션을 올린다. 기본은 **보기만** 한다.

.DESCRIPTION
  기본 실행은 로컬과 원격의 마이그레이션 목록을 나란히 보여 주고 끝난다.
  실제로 올리려면 `-Apply` 를 붙여야 한다.

  이렇게 나눈 이유가 있다. 이 프로젝트에는 함정이 두 개 겹쳐 있다.

  1. `007` 부터 `011` 까지는 Supabase SQL Editor 에서 손으로 적용됐다. 그러면
     원격 `supabase_migrations.schema_migrations` 에 기록이 남지 않는다. CLI 는
     기록만 보므로 이것들을 "미적용" 으로 판단하고 다시 실행하려 든다.
     `001` 처럼 `create table` 이 든 파일이 재실행되면 실패하거나, 더 나쁘게는
     일부만 적용된 상태로 멈춘다.

  2. 파일 이름이 `012_place_alert_management_rpcs.sql` 형식이다. CLI 가 만드는
     이름은 `20260905150519_name.sql` 이고, 버전 비교도 그 형식을 전제한다.

  그래서 `migration list` 를 먼저 눈으로 확인해야 한다. 원격에 `007`~`011` 이
  안 보이면, push 하기 전에 아래처럼 이미 적용됐다고 표시해 둔다.

      supabase migration repair --status applied 007
      ...
      supabase migration repair --status applied 011

.EXAMPLE
  .\tools\apply-migrations.ps1            # 로컬 vs 원격 비교만
  .\tools\apply-migrations.ps1 -Apply     # 확인 후 실제 push
#>
param(
  [switch]$Apply,
  [string]$ProjectRef = 'usetuwqbzkmywmtgwwdx'
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Get-Command supabase -ErrorAction SilentlyContinue)) {
  throw "supabase CLI 가 PATH 에 없습니다. https://supabase.com/docs/guides/cli"
}

$envFile = Join-Path $repoRoot '.env.local'
if (-not (Test-Path -LiteralPath $envFile)) {
  throw @"
.env.local 이 없습니다. .env.example 을 복사해 아래 값을 채우세요.

  SUPABASE_URL=
  SUPABASE_PUBLISHABLE_KEY=

DB 비밀번호는 파일에 두지 마세요. `supabase link` 가 물어보면 그때 입력합니다.
"@
}

Write-Output "프로젝트: $ProjectRef"
Write-Output ""

# link 는 비밀번호를 대화형으로 묻는다. 파일이나 인자로 받지 않는다.
& supabase link --project-ref $ProjectRef
if ($LASTEXITCODE -ne 0) { throw "supabase link 실패" }

Write-Output ""
Write-Output "=== 로컬 vs 원격 마이그레이션 ==="
& supabase migration list
if ($LASTEXITCODE -ne 0) { throw "supabase migration list 실패" }

if (-not $Apply) {
  Write-Output ""
  Write-Output @"
보기만 했습니다. 위 목록에서 확인할 것:

  - Remote 열에 007~011 이 보이는가?
    안 보이면 SQL Editor 로 적용된 것이 기록되지 않은 상태다. 먼저
    `supabase migration repair --status applied <version>` 로 표시한 뒤에
    push 해야 001 부터 재실행되지 않는다.

  - Local 에만 있는 것이 012~015 뿐인가?
    그 넷만 남아야 정상이다.

확인이 끝났으면 -Apply 를 붙여 다시 실행하세요.
"@
  exit 0
}

Write-Output ""
Write-Output "=== db push ==="
& supabase db push
if ($LASTEXITCODE -ne 0) { throw "supabase db push 실패" }

Write-Output ""
Write-Output @"
적용됐습니다. 다음은 SQL Editor 에서 순서대로 실행하세요.

읽기 전용 검증:
  supabase/verification_after_012.sql
  supabase/verification_after_013.sql
  supabase/verification_after_014.sql
  supabase/verification_after_015.sql

롤백 전용 네거티브 테스트(각 파일이 스스로 롤백한다):
  supabase/negative_tests_after_012.sql
  supabase/negative_tests_after_013.sql
  supabase/negative_tests_after_014.sql
  supabase/negative_tests_after_015.sql

결과는 supabase/deployment-log.md 에 남기세요.
"@
