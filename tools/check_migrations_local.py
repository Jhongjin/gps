#!/usr/bin/env python3
"""마이그레이션 전체를 로컬 PostgreSQL 에 순서대로 적용해 본다.

`supabase db reset` 이 정석이지만 Docker 가 필요하고, 이 워크스테이션에는 없다.
마이그레이션이 SQL 파일로만 쌓이면 문법 오류·없는 칼럼·잘못된 의존 순서가
프로덕션에 올리는 순간에야 드러난다 — 그리고 그때는 `001` 부터 다시 돌리려
드는 CLI 와 함께 드러난다(`supabase/README.md`).

이 스크립트는 임시 클러스터를 `initdb` 로 만들어 띄우고, Supabase 가 제공하는
전제(`auth.uid()`, `authenticated` 역할, pgcrypto)를 최소 shim 으로 넣은 뒤
`migrations/NNN_*.sql` 을 번호순으로 적용한다. 끝나면 `verification_after_*.sql`
을 읽기 전용 스모크로 돌리고 클러스터를 지운다. 서비스로 깔린 PostgreSQL 은
건드리지 않는다.

    python tools/check_migrations_local.py            # 전체
    python tools/check_migrations_local.py --keep     # 실패 시 클러스터를 남긴다
"""

from __future__ import annotations

import os
import re
import shutil
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIGRATIONS = ROOT / "supabase" / "migrations"
SUPABASE = ROOT / "supabase"

# Supabase 가 프로젝트마다 제공하는 것들. 마이그레이션은 이것이 있다고 가정한다.
SHIM_SQL = """
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;
create extension if not exists pgcrypto;
create schema if not exists auth;
-- Supabase auth 의 사용자 표. 마이그레이션이 참조하는 칼럼만 둔다:
-- 001 은 id 를 외래키로, 004 는 트리거에서 email 과 raw_user_meta_data 를 읽고,
-- 부정 테스트는 aud·role 까지 넣는다.
create table auth.users (
  id uuid primary key default gen_random_uuid(),
  aud text,
  role text,
  email text,
  raw_user_meta_data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
-- 테스트에서 `set local request.jwt.claim.sub = '<uuid>'` 로 호출자를 흉내낸다.
create or replace function auth.uid() returns uuid
language sql stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated, service_role;
-- Supabase 는 public 스키마의 표·시퀀스·함수에 이 세 역할의 권한을 기본으로
-- 준다. 행 단위 접근은 RLS 가 가른다. 이 기본 권한이 없으면 부정 테스트가
-- RLS 가 아니라 표 권한에서 막혀, 정작 보려던 것을 못 본다.
grant usage on schema public to anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  grant all on tables to anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  grant all on sequences to anon, authenticated, service_role;
alter default privileges for role postgres in schema public
  grant all on functions to anon, authenticated, service_role;
"""


def find_pg_bin() -> Path | None:
    for name in ("pg_ctl", "pg_ctl.exe"):
        found = shutil.which(name)
        if found:
            return Path(found).parent
    # 이 워크스테이션은 설치기 없는 포터블 바이너리를 Flutter 와 같은 자리에 둔다.
    # EDB 설치기는 재시작이 보류된 상태에서 조용히 실패한다.
    portable = Path("D:/Codex/toolchains/postgres/pgsql/bin")
    if (portable / "pg_ctl.exe").exists():
        return portable
    candidates = [Path("C:/Program Files/PostgreSQL"), Path("/usr/lib/postgresql")]
    for base in candidates:
        if not base.exists():
            continue
        for version in sorted(base.glob("*"), reverse=True):
            sub = version / "bin"
            if (sub / "pg_ctl.exe").exists() or (sub / "pg_ctl").exists():
                return sub
    return None


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def run_detached(cmd: list[str], env: dict[str, str]) -> int:
    """pg_ctl start/stop 전용.

    `pg_ctl start` 가 띄운 서버 프로세스는 부모의 stdout 파이프를 물려받고 닫지
    않는다. `capture_output` 으로 부르면 파이프 EOF 를 기다리며 영원히 선다 —
    첫 실행이 그렇게 서버만 띄운 채 10분을 멈춰 있었다. 출력은 `-l` 로그로 간다.
    """
    return subprocess.run(
        cmd,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env,
        timeout=180,
    ).returncode


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    # stdin 을 닫는다. 부모 셸의 stdin 을 물려받은 psql 이 그것을 기다리며 서는
    # 경우가 있었다. timeout 은 멈춤을 오류로 바꾼다 — 조용히 서 있는 것보다 낫다.
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        stdin=subprocess.DEVNULL,
        timeout=kwargs.pop("timeout", 180),
        **kwargs,
    )


def migration_files() -> list[Path]:
    files = [p for p in MIGRATIONS.glob("*.sql") if re.match(r"^\d{3}_", p.name)]
    return sorted(files, key=lambda p: int(p.name[:3]))


def main(argv: list[str]) -> int:
    # 콘솔이 cp949 여도 psql 의 UTF-8 메시지를 찍다가 죽지 않게 한다.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    keep = "--keep" in argv
    pg_bin = find_pg_bin()
    if pg_bin is None:
        print(
            "PostgreSQL 을 찾지 못했다. 포터블 바이너리를 "
            "D:/Codex/toolchains/postgres/pgsql 에 풀거나 PATH 에 pg_ctl 을 둔다."
        )
        return 1

    exe = ".exe" if os.name == "nt" else ""
    initdb = str(pg_bin / f"initdb{exe}")
    pg_ctl = str(pg_bin / f"pg_ctl{exe}")
    psql = str(pg_bin / f"psql{exe}")

    port = free_port()
    workdir = Path(tempfile.mkdtemp(prefix="gyeote-pg-"))
    data = workdir / "data"
    log = workdir / "server.log"
    # LC_ALL 을 건드리지 않는다. Windows 의 initdb 는 그 값을 로케일 이름으로
    # 해석하려다 조용히 실패한다. 클러스터 로케일은 --locale=C 로 충분하다.
    env = dict(os.environ, PGCLIENTENCODING="UTF8")

    def stop():
        run_detached([pg_ctl, "-D", str(data), "-m", "fast", "stop"], env)

    def sql(args: list[str], db: str = "postgres") -> subprocess.CompletedProcess:
        return run(
            [psql, "-h", "127.0.0.1", "-p", str(port), "-U", "postgres", "-d", db,
             "-X", "-v", "ON_ERROR_STOP=1", "-q", *args],
            env=env,
        )

    # postgres.exe 가 간헐적으로 fail-fast(0xC0000409) 로 죽는 환경이 있다.
    # 재시작이 보류된 채 런타임이 바뀐 Windows 에서 봤다. 한 번 더 시도한다.
    init = None
    for _attempt in range(3):
        shutil.rmtree(data, ignore_errors=True)
        init = run(
            [initdb, "-D", str(data), "-U", "postgres", "--auth=trust", "-E", "UTF8",
             "--locale=C", "--no-sync"],
            env=env,
        )
        if init.returncode == 0:
            break
    if init is None or init.returncode != 0:
        print("initdb 실패 (exit %d):" % init.returncode)
        print(init.stdout)
        print("\n" + init.stderr)
        return 1

    started = 1
    for _attempt in range(3):
        started = run_detached(
            [pg_ctl, "-D", str(data), "-l", str(log), "-w", "-t", "60", "-o",
             f"-p {port} -c listen_addresses=127.0.0.1 -c fsync=off", "start"],
            env,
        )
        if started == 0:
            break
        time.sleep(2)
    if started != 0:
        print(f"서버 시작 실패 (pg_ctl exit {started})")
        if log.exists():
            print(log.read_text(encoding="utf-8", errors="replace")[-2000:])
        return 1

    failed = False
    try:
        for _ in range(30):
            if sql(["-c", "select 1"]).returncode == 0:
                break
            time.sleep(0.5)

        created = sql(["-c", "create database gyeote"])
        if created.returncode != 0:
            print("DB 생성 실패:\n" + created.stderr)
            return 1

        # 인자로 넘기면 Windows 가 콘솔 코드페이지로 바꿔 한국어 주석이 깨진다.
        # 파일로 쓰고 -f 로 읽힌다.
        shim_path = workdir / "shim.sql"
        shim_path.write_text(SHIM_SQL, encoding="utf-8")
        shim = sql(["-f", str(shim_path)], db="gyeote")
        if shim.returncode != 0:
            print("shim 실패:\n" + shim.stderr)
            return 1

        files = migration_files()
        for path in files:
            result = sql(["-f", str(path)], db="gyeote")
            if result.returncode != 0:
                failed = True
                print(f"FAIL {path.name}")
                print(result.stderr.strip())
                break
            print(f"  ok  {path.name}")

        if not failed:
            for path in sorted(SUPABASE.glob("verification_after_*.sql")):
                result = sql(["-f", str(path)], db="gyeote")
                if result.returncode != 0:
                    failed = True
                    print(f"FAIL {path.name} (읽기 전용 검증)")
                    print(result.stderr.strip())
                    break
                print(f"  ok  {path.name}")

        # 롤백 전용 부정 테스트. 트랜잭션 안에서 픽스처를 만들고 RLS·RPC 가
        # 막아야 할 것을 막는지 본 뒤 전부 되돌린다. 결과 행은 (name, passed, detail).
        if not failed:
            for path in sorted(SUPABASE.glob("negative_tests_after_*.sql")):
                result = sql(["-A", "-t", "-F", "\t", "-f", str(path)], db="gyeote")
                if result.returncode != 0:
                    failed = True
                    print(f"FAIL {path.name} (부정 테스트 실행 오류)")
                    print(result.stderr.strip())
                    break
                # 각 파일은 마지막에 한 줄을 낸다:
                #   bool_and(passed) | {이름: 통과} | {이름: 상세 (실패만)}
                rows = [line.split("\t") for line in result.stdout.splitlines() if "\t" in line]
                summary = rows[-1] if rows else []
                if not summary or summary[0].strip() != "t":
                    failed = True
                    print(f"FAIL {path.name}")
                    if len(summary) >= 3 and summary[2].strip():
                        print("     " + summary[2].strip())
                    elif summary:
                        print("     " + " | ".join(cell.strip() for cell in summary))
                    else:
                        print("     결과 행이 없다")
                    break
                checks = summary[1].count(":") if len(summary) > 1 else 0
                print(f"  ok  {path.name} ({checks} assertions)")

        if failed:
            print("\n마이그레이션 체인이 깨졌다. 프로덕션에 올리기 전에 고친다.")
            return 1

        print(f"\n{len(files)}개 마이그레이션이 빈 클러스터에 순서대로 적용된다.")
        return 0
    finally:
        stop()
        if keep and failed:
            print(f"클러스터를 남겼다: {data} (port {port})")
        else:
            shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
