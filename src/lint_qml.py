# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Run qmllint on QML files with the DMS qs.* imports resolved.

Quickshell resolves qs.* modules at runtime without qmldir files, so
qmllint cannot see them on its own. This script mirrors the installed
DMS tree into a git-ignored import directory with generated qmldir
files, refreshes .qmlls.ini so the editor lints the same way, and then
runs qmllint. Invoked by prek with the QML files to check. Exits
successfully when DMS or qmllint is not installed, like on the lint CI
runner.
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SHIM_ROOT = REPO_ROOT / ".qmllint-imports"

DMS_ROOTS = (
    Path.home() / ".config" / "quickshell" / "dms",
    Path("/usr/share/quickshell/dms"),
)
QMLLINT_FALLBACKS = (
    Path("/usr/lib64/qt6/bin/qmllint"),
    Path("/usr/lib/qt6/bin/qmllint"),
)
SYSTEM_QML_DIRS = (
    Path("/usr/lib64/qt6/qml"),
    Path("/usr/lib/qt6/qml"),
)

SINGLETON_PRAGMA = re.compile(r"^\s*pragma\s+Singleton", re.MULTILINE)
MODULE_IDENTIFIER = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def find_dms_root() -> Path | None:
    for root in DMS_ROOTS:
        if (root / "shell.qml").is_file():
            return root
    return None


def find_qmllint() -> str | None:
    qmllint = shutil.which("qmllint")
    if qmllint is not None:
        return qmllint
    for fallback in QMLLINT_FALLBACKS:
        if fallback.is_file():
            return str(fallback)
    return None


def is_singleton(file: Path) -> bool:
    return file.suffix == ".qml" and SINGLETON_PRAGMA.search(file.read_text(encoding="utf-8")) is not None


def qmldir_content(module: str, files: list[Path]) -> str:
    lines = [f"module {module}"]
    lines.extend(f"{'singleton ' if is_singleton(file) else ''}{file.stem} 1.0 {file.name}" for file in files)
    return "\n".join(lines) + "\n"


def generate_shims(dms_root: Path) -> None:
    qs_root = SHIM_ROOT / "qs"
    if qs_root.is_symlink():
        qs_root.unlink()
    elif qs_root.exists():
        shutil.rmtree(qs_root)

    for directory in (dms_root, *sorted(dms_root.rglob("*/"))):
        relative = directory.relative_to(dms_root)
        if not all(MODULE_IDENTIFIER.match(part) for part in relative.parts):
            continue

        files = sorted(
            file for file in directory.iterdir() if file.suffix in {".qml", ".js"} and file.name[0].isupper()
        )
        if not files:
            continue

        shim = qs_root / relative
        shim.mkdir(parents=True, exist_ok=True)
        for file in files:
            (shim / file.name).symlink_to(file)

        module = ".".join(["qs", *relative.parts])
        (shim / "qmldir").write_text(qmldir_content(module, files), encoding="utf-8")


def import_paths() -> list[Path]:
    return [SHIM_ROOT, *(path for path in SYSTEM_QML_DIRS if path.is_dir())]


def write_qmlls_ini() -> None:
    ini = REPO_ROOT / ".qmlls.ini"
    ini.unlink(missing_ok=True)
    paths = ":".join(str(path) for path in import_paths())
    ini.write_text(f"[General]\nno-cmake-calls=true\nimportPaths={paths}\n", encoding="utf-8")


def main(files: list[str]) -> int:
    if not files:
        return 0

    dms_root = find_dms_root()
    if dms_root is None:
        sys.stderr.write("qmllint skipped: no DMS installation found\n")
        return 0

    qmllint = find_qmllint()
    if qmllint is None:
        sys.stderr.write("qmllint skipped: no qmllint executable found\n")
        return 0

    generate_shims(dms_root)
    write_qmlls_ini()

    flags = [flag for path in import_paths() for flag in ("-I", str(path))]
    return subprocess.run([qmllint, "-W", "0", *flags, *files], check=False).returncode


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
