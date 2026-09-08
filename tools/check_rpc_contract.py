#!/usr/bin/env python3
"""Dart 가 부르는 Supabase RPC 와 SQL 이 정의한 함수가 맞는지 본다.

RPC 는 이름과 인자 이름이 문자열로만 이어져 있다. 컴파일러도 분석기도 못 잡고,
그 화면을 실제로 눌러 봐야 터진다. 마이그레이션이 아직 프로덕션에 안 올라간
상태에서는 더 위험하다 — 로컬에서 SQL 을 고쳐도 배포된 앱은 옛 이름을 부른다.

    python tools/check_rpc_contract.py
"""
from __future__ import annotations

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DART = os.path.join(REPO, "apps", "gyeote_flutter", "lib")
SQL = os.path.join(REPO, "supabase", "migrations")

# 호출부는 `.rpc('name', params: {...})` 이거나 이름이 다음 줄에 오는 형태다.
CALL = re.compile(r"\.rpc\(\s*'(?P<name>[a-z0-9_]+)'", re.S)

# params: { ... } 블록만 본다. 중첩 맵(event_metadata 등)은 깊이로 걸러낸다.
PARAMS_BLOCK = re.compile(r"params:\s*\{", re.S)
KEY = re.compile(r"'([a-z0-9_]+)'\s*:")

# create [or replace] function [public.]name(args)
DEF = re.compile(
    r"create\s+(?:or\s+replace\s+)?function\s+(?:public\.)?(?P<name>[a-z0-9_]+)\s*\((?P<args>.*?)\)\s*returns",
    re.S | re.I,
)
ARG = re.compile(r"(?:^|,)\s*(?P<name>[a-z0-9_]+)\s+[a-z]", re.I)


def _params_after(text: str, start: int) -> set[str]:
    """`params: {` 블록의 **최상위** 키만 모은다."""
    m = PARAMS_BLOCK.search(text, start, start + 400)
    if not m:
        return set()
    i, depth, top = m.end(), 1, []
    while i < len(text) and depth > 0:
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        elif c == "'" and depth == 1:
            k = KEY.match(text, i)
            if k:
                top.append(k.group(1))
                i = k.end()
                continue
        i += 1
    return set(top)


def dart_calls() -> dict[str, set[str]]:
    calls: dict[str, set[str]] = {}
    for root, _dirs, files in os.walk(DART):
        for f in files:
            if not f.endswith(".dart"):
                continue
            text = open(os.path.join(root, f), encoding="utf-8").read()
            for m in CALL.finditer(text):
                name = m.group("name")
                params = _params_after(text, m.end())
                calls.setdefault(name, set()).update(params)
    return calls


def sql_defs() -> dict[str, set[str]]:
    defs: dict[str, set[str]] = {}
    for f in sorted(os.listdir(SQL)):
        if not f.endswith(".sql"):
            continue
        text = open(os.path.join(SQL, f), encoding="utf-8").read()
        for m in DEF.finditer(text):
            args = {a.group("name").lower() for a in ARG.finditer(m.group("args"))}
            # 나중 마이그레이션이 앞선 정의를 대체한다.
            defs[m.group("name").lower()] = args
    return defs


def main() -> int:
    calls = dart_calls()
    defs = sql_defs()
    problems: list[str] = []

    for name in sorted(calls):
        if name not in defs:
            problems.append(
                f"MISSING  {name}() 를 Dart 가 부르는데 마이그레이션에 정의가 없다"
            )
            continue
        unknown = calls[name] - defs[name]
        if unknown:
            problems.append(
                f"ARGS     {name}() 인자 불일치: Dart 가 보내는 {sorted(unknown)} 가"
                f" SQL 정의 {sorted(defs[name])} 에 없다"
            )

    print(f"Dart RPC 호출 {len(calls)}개 / SQL 함수 정의 {len(defs)}개")
    print()
    for name in sorted(calls):
        mark = "ok " if name in defs and not (calls[name] - defs[name]) else "FAIL"
        print(f"  {mark} {name}({', '.join(sorted(calls[name]))})")

    if problems:
        print()
        for p in problems:
            print(p)
        return 1

    print("\n계약 일치.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
