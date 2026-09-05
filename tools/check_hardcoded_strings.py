#!/usr/bin/env python3
"""UI 코드에 새로 들어온 하드코딩 한국어 문자열을 잡는다.

사용자에게 보이는 문자열은 `lib/l10n/*.arb` 에 두고 `AppL10n` 으로 읽어야 한다.
위젯 안에 한국어 리터럴을 직접 박으면 그 화면은 번역할 수 없게 되고, 나중에
두 배로 걷어내야 한다.

마이그레이션은 끝났고 베이스라인은 비어 있다. 즉 이제 **한 건이라도 생기면
실패**한다. 베이스라인은 되돌아갈 때를 위해 남겨 둔 장치이지, 새 빚을 허용하는
자리가 아니다.

    python tools/check_hardcoded_strings.py                 # 검사
    python tools/check_hardcoded_strings.py --update        # 베이스라인 갱신
"""
from __future__ import annotations

import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB_ROOT = os.path.join(REPO_ROOT, "apps", "gyeote_flutter", "lib")
BASELINE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "hardcoded-strings-baseline.json")

# 생성물과 ARB 원본은 검사 대상이 아니다.
SKIP_DIRS = {os.path.join("lib", "l10n")}

HANGUL_LITERAL = re.compile(r"'[^']*[가-힣][^']*'")
LINE_COMMENT = re.compile(r"//.*$")


def count_file(path: str) -> int:
    total = 0
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            # 주석은 한국어로 써도 된다. 사용자에게 보이지 않는다.
            total += len(HANGUL_LITERAL.findall(LINE_COMMENT.sub("", line)))
    return total


def scan() -> dict[str, int]:
    counts: dict[str, int] = {}
    for root, _dirs, files in os.walk(LIB_ROOT):
        rel_root = os.path.relpath(root, os.path.join(REPO_ROOT, "apps", "gyeote_flutter"))
        if any(rel_root.startswith(skip) for skip in SKIP_DIRS):
            continue
        for name in files:
            if not name.endswith(".dart"):
                continue
            full = os.path.join(root, name)
            n = count_file(full)
            if n:
                rel = os.path.relpath(full, REPO_ROOT).replace(os.sep, "/")
                counts[rel] = n
    return counts


def main() -> int:
    counts = scan()
    total = sum(counts.values())

    if "--update" in sys.argv:
        with open(BASELINE, "w", encoding="utf-8") as handle:
            json.dump(dict(sorted(counts.items())), handle, ensure_ascii=False, indent=2)
            handle.write("\n")
        print(f"베이스라인 갱신: {total}건 / {len(counts)}개 파일")
        return 0

    if not os.path.exists(BASELINE):
        print("베이스라인이 없습니다. 먼저 --update 로 생성하세요.", file=sys.stderr)
        return 2

    with open(BASELINE, encoding="utf-8") as handle:
        baseline: dict[str, int] = json.load(handle)

    failed = False
    for path in sorted(counts):
        allowed = baseline.get(path, 0)
        if counts[path] > allowed:
            print(f"FAIL {path} : 하드코딩 {counts[path]}건 (허용 {allowed}건)")
            failed = True

    base_total = sum(baseline.values())
    print(f"\n하드코딩 한국어 문자열: {total}건 (베이스라인 {base_total}건)")

    if failed:
        print("\n새 문자열은 apps/gyeote_flutter/lib/l10n/app_ko.arb 에 넣고 AppL10n 으로 읽으세요.")
        print("파일을 정리했다면 `python tools/check_hardcoded_strings.py --update` 로 베이스라인을 낮추세요.")
        return 1

    if total < base_total:
        print(f"베이스라인보다 {base_total - total}건 줄었습니다. --update 로 반영하세요.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
