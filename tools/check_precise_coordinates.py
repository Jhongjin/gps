#!/usr/bin/env python3
"""정확한 좌표가 다시 서버로 나가지 않는지 확인한다.

018 이전에는 `latest_locations` 와 `location_history` 에 `raw_lat`/`raw_lng` 가
함께 올라갔다. 그 값을 읽는 RPC 도 뷰도 없었는데, 사용자가 공유 정확도를
'동네만'이나 '숨김'으로 두어도 정확한 좌표는 그대로 쌓였다. 화면이 약속한 것과
저장된 것이 달랐다는 뜻이다.

이런 결함은 조용하다. 아무것도 깨지지 않고, 테스트도 통과하고, 몇 달 뒤에나
드러난다. 그래서 사람 눈이 아니라 CI 가 본다.

규칙:

1. 업로드 경로(Dart/Kotlin)에서 `raw_lat` / `raw_lng` 칸을 쓰지 않는다.
2. `rawCoordinate` 는 기기 안에서만 산다. 업로드 행을 만드는 파일에서
   참조하면 안 된다.
3. 민감 장소 이름은 채널로 내려가지 않는다.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "apps" / "gyeote_flutter"

# 업로드 행을 조립하는 곳. 여기 정확한 좌표가 들어가면 서버로 나간다.
UPLOAD_SOURCES = [
    APP / "lib" / "src" / "core" / "backend" / "supabase_backend.dart",
    APP
    / "android"
    / "app"
    / "src"
    / "main"
    / "kotlin"
    / "app"
    / "gyeote"
    / "gyeote"
    / "GyeoteLocationUploadQueue.kt",
]

RAW_COLUMN = re.compile(r"""["']raw_(lat|lng)["']""")
RAW_COORDINATE = re.compile(r"""["']rawCoordinate["']""")


def strip_comments(text: str) -> str:
    """주석은 규칙 설명에 칸 이름을 그대로 적는다. 코드만 본다."""
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)


def main() -> int:
    problems: list[str] = []

    for path in UPLOAD_SOURCES:
        if not path.exists():
            problems.append(f"검사 대상이 없다: {path.relative_to(ROOT)}")
            continue

        code = strip_comments(path.read_text(encoding="utf-8"))
        rel = path.relative_to(ROOT)

        for match in RAW_COLUMN.finditer(code):
            line = code[: match.start()].count("\n") + 1
            problems.append(f"{rel}:{line} 업로드 행에 {match.group(0)} 이 있다")

        for match in RAW_COORDINATE.finditer(code):
            line = code[: match.start()].count("\n") + 1
            problems.append(
                f"{rel}:{line} 업로드 경로가 rawCoordinate 를 읽는다"
            )

    bridge = APP / "lib" / "src" / "core" / "location" / "location_bridge.dart"
    if bridge.exists():
        code = strip_comments(bridge.read_text(encoding="utf-8"))
        # 민감 장소는 toChannel() 로만 나가야 한다. toJson() 은 이름을 담는다.
        if re.search(r"privatePlaces[^\n]*toJson\(\)", code):
            problems.append(
                f"{bridge.relative_to(ROOT)} 민감 장소를 toJson() 으로 내려보낸다 "
                "— 이름이 네이티브로 넘어간다"
            )

    if problems:
        print("정확한 좌표가 서버로 나갈 수 있다:\n")
        for problem in problems:
            print(f"  {problem}")
        print(
            "\n원시 좌표는 기기 안에서 민감 장소 판정에만 쓴다. "
            "서버에는 가려진 좌표만 간다."
        )
        return 1

    print("업로드 경로에 정확한 좌표 없음.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
