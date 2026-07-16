# SPDX-FileCopyrightText: Elias Mueller
#
# SPDX-License-Identifier: MIT

"""Generate the QML tooling files for the DMS qs.* imports.

Quickshell resolves qs.* modules at runtime without qmldir files, so
qmllint and qmlls cannot see them on their own. This script mirrors
the installed DMS tree into a git-ignored import directory with
generated qmldir files and refreshes .qmlls.ini to point there. Run
by just init and reused by the qmllint hook. Exits successfully when
DMS is not installed, like on the lint CI runner.
"""

import re
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SHIM_ROOT = REPO_ROOT / ".qmllint-imports"

DMS_ROOTS = (
    Path.home() / ".config" / "quickshell" / "dms",
    Path("/usr/share/quickshell/dms"),
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


def generate(dms_root: Path) -> None:
    generate_shims(dms_root)
    write_qmlls_ini()


def main() -> int:
    dms_root = find_dms_root()
    if dms_root is None:
        sys.stderr.write("qml tooling skipped: no DMS installation found\n")
        return 0
    generate(dms_root)
    return 0


if __name__ == "__main__":
    sys.exit(main())
