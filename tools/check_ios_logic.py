#!/usr/bin/env python3
"""iOS 네이티브의 순수 로직을 Xcode 없이 검증한다.

이 워크스페이스는 Windows 라 iOS 앱을 빌드할 수 없다. 그렇다고 iOS 코드를
"소스만 있고 검증 없음"으로 두면, 안드로이드에서만 가려지고 iOS 에서는 정확한
좌표가 나가는 식의 플랫폼 간 결함이 조용히 생긴다.

`AppDelegate.swift` 의 `GyeotePortable` 구역은 Foundation 만 쓴다. 여기서 그
구역을 잘라내 `tools/ios_logic_tests.swift` 와 함께 Swift for Windows 로
컴파일하고 실행한다. 컴파일되는 것은 배포되는 바로 그 코드다.

swiftc 가 없으면 **건너뛰지 않고 실패한다**. 검증이 없는 것을 통과로 세면
이 도구가 존재하는 이유가 사라진다. CI 에서 명시적으로 생략하려면
`--allow-missing-toolchain` 을 준다.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_DELEGATE = ROOT / "apps" / "gyeote_flutter" / "ios" / "Runner" / "AppDelegate.swift"
TESTS = ROOT / "tools" / "ios_logic_tests.swift"

BEGIN = "// MARK: - GyeotePortable"
END = "// MARK: - end GyeotePortable"
FORBIDDEN_IMPORTS = ("UIKit", "CoreLocation", "UserNotifications", "Flutter")


def portable_block() -> str:
    source = APP_DELEGATE.read_text(encoding="utf-8")
    start = source.find(BEGIN)
    end = source.find(END)
    if start < 0 or end < 0 or end < start:
        raise SystemExit(f"{APP_DELEGATE.relative_to(ROOT)} 에 GyeotePortable 구역이 없다")
    block = source[start:end]
    # 주석은 금지 프레임워크 이름을 설명 삼아 적을 수 있다. 코드만 본다.
    code = re.sub(r"/\*.*?\*/", "", block, flags=re.DOTALL)
    code = re.sub(r"^\s*//.*$", "", code, flags=re.MULTILINE)
    for name in FORBIDDEN_IMPORTS:
        if re.search(r"\b" + re.escape(name) + r"\b", code):
            raise SystemExit(f"GyeotePortable 구역이 {name} 을 참조한다 — 이식 가능해야 한다")
    return block


def find_swiftc() -> str | None:
    found = shutil.which("swiftc")
    if found:
        return found
    candidates = [
        Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Swift" / "Toolchains",
        Path("C:/Program Files/Swift/Toolchains"),
    ]
    for base in candidates:
        if not base.exists():
            continue
        for toolchain in sorted(base.glob("*"), reverse=True):
            exe = toolchain / "usr" / "bin" / "swiftc.exe"
            if exe.exists():
                return str(exe)
    return None


def main(argv: list[str]) -> int:
    allow_missing = "--allow-missing-toolchain" in argv
    block = portable_block()

    swiftc = find_swiftc()
    if swiftc is None:
        print("swiftc 를 찾지 못했다. winget install Swift.Toolchain")
        return 0 if allow_missing else 1

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        source = tmp_path / "portable_test.swift"
        source.write_text(
            "import Foundation\n\n" + block + "\n\n" + TESTS.read_text(encoding="utf-8"),
            encoding="utf-8",
        )
        exe = tmp_path / ("portable_test.exe" if os.name == "nt" else "portable_test")

        # Windows 의 swiftc 는 런타임 DLL 과 SDKROOT 를 환경에서 찾는다. 설치기가
        # 사용자 환경변수에 넣어 두지만, 이미 떠 있던 셸은 그걸 모른다. 찾은
        # 툴체인 경로에서 필요한 것을 여기서 직접 만들어 준다.
        env = dict(os.environ)
        toolchain_bin = Path(swiftc).parent
        swift_root = toolchain_bin.parents[3] if len(toolchain_bin.parents) > 3 else None
        if os.name == "nt" and swift_root is not None:
            version = toolchain_bin.parents[1].name.split("+")[0]
            runtime_bin = swift_root / "Runtimes" / version / "usr" / "bin"
            sdk = swift_root / "Platforms" / version / "Windows.platform" / "Developer" / "SDKs" / "Windows.sdk"
            env["PATH"] = os.pathsep.join([str(toolchain_bin), str(runtime_bin), env.get("PATH", "")])
            if sdk.exists() and not env.get("SDKROOT"):
                env["SDKROOT"] = str(sdk) + os.sep

        compile_result = subprocess.run(
            [swiftc, "-O", str(source), "-o", str(exe)],
            capture_output=True,
            text=True,
            # 콘솔 코드페이지(cp949)로 읽으면 컴파일러의 UTF-8 메시지에서 죽는다.
            encoding="utf-8",
            errors="replace",
            env=env,
        )
        if compile_result.returncode != 0:
            print("Swift 컴파일 실패:\n" + compile_result.stderr)
            return 1

        run_result = subprocess.run(
            [str(exe)],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            env=env,
        )
        print(run_result.stdout.strip())
        if run_result.stderr.strip():
            print(run_result.stderr.strip())
        return run_result.returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
