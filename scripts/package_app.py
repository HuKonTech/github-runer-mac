#!/usr/bin/env python3
"""Build a distributable desktop bundle with PyInstaller."""

from __future__ import annotations

import argparse
import os
import shutil
from pathlib import Path

from PyInstaller.__main__ import run as pyinstaller_run
from PyInstaller.utils.hooks import collect_submodules


APP_NAME = "Face-Local"
ROOT = Path(__file__).resolve().parent.parent
BUILD_DIR = ROOT / "build" / "pyinstaller"
DIST_DIR = ROOT / "dist"
ENTRYPOINT = ROOT / "app" / "main.py"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True, help="Display version for generated bundles.")
    return parser.parse_args()


def build() -> None:
    separator = ";" if os.name == "nt" else ":"
    data_args: list[str] = []

    for source, destination in iter_data_files():
        data_args.extend(["--add-data", f"{source}{separator}{destination}"])

    hidden_imports = sorted(set(collect_submodules("app")))

    args = [
        "--noconfirm",
        "--clean",
        "--windowed",
        "--name",
        APP_NAME,
        "--distpath",
        str(DIST_DIR),
        "--workpath",
        str(BUILD_DIR),
        "--specpath",
        str(BUILD_DIR),
        "--paths",
        str(ROOT),
        *data_args,
    ]

    if os.name == "posix" and os.uname().sysname == "Darwin":
        args.extend(["--osx-bundle-identifier", "local.face.recognizer"])

    for hidden_import in hidden_imports:
        args.extend(["--hidden-import", hidden_import])

    args.append(str(ENTRYPOINT))
    pyinstaller_run(args)


def iter_data_files() -> list[tuple[str, str]]:
    data_files: list[tuple[str, str]] = []
    for filename in ("config.example.yaml",):
        path = ROOT / filename
        if path.exists():
            data_files.append((str(path), "."))

    models_dir = ROOT / "models"
    if models_dir.exists():
        for model_file in sorted(models_dir.iterdir()):
            if model_file.is_file():
                data_files.append((str(model_file), "models"))

    return data_files


def clean() -> None:
    shutil.rmtree(BUILD_DIR, ignore_errors=True)
    shutil.rmtree(DIST_DIR / APP_NAME, ignore_errors=True)
    shutil.rmtree(DIST_DIR / f"{APP_NAME}.app", ignore_errors=True)


def inject_version(version: str) -> None:
    """Overwrite app/__init__.py with the build-time version."""
    init_path = ROOT / "app" / "__init__.py"
    init_path.write_text(
        f'"""Face-Local: offline face grouping and person labeling application."""\n\n'
        f'__version__ = "{version}"\n',
        encoding="utf-8",
    )


def main() -> None:
    args = parse_args()
    inject_version(args.version)
    clean()
    build()


if __name__ == "__main__":
    main()
