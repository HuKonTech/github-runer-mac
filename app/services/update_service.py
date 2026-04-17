"""GitHub release update checker and downloader."""

from __future__ import annotations

import logging
import re
import sys
import tempfile
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

log = logging.getLogger(__name__)

_REPO = "BenKoncsik/local_ai_face_recognizer"
_API_URL = f"https://api.github.com/repos/{_REPO}/releases/latest"


@dataclass
class ReleaseInfo:
    version: str
    tag: str
    url: str          # browser html url
    asset_name: str
    asset_url: str
    asset_size: int   # bytes


def _parse_version(v: str) -> tuple[int, ...]:
    v = v.lstrip("v")
    m = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)", v)
    if not m:
        return (0,)
    return tuple(int(x) for x in m.groups())


def _pick_asset(assets: list[dict]) -> Optional[dict]:
    """Return the best asset for the running OS, or None."""
    platform = sys.platform

    def score(a: dict) -> int:
        n = a["name"].lower()
        if platform == "darwin":
            # prefer installer DMG over zip
            if n.endswith(".dmg") and "macos" in n:
                return 2
            if n.endswith(".zip") and "macos" in n:
                return 1
        elif platform == "win32":
            if n.endswith(".exe") and "windows" in n:
                return 2
            if n.endswith(".zip") and "windows" in n:
                return 1
        else:
            if n.endswith(".deb") and "linux" in n:
                return 2
            if n.endswith(".tar.gz") and "linux" in n:
                return 1
        return 0

    ranked = sorted(assets, key=score, reverse=True)
    return ranked[0] if ranked and score(ranked[0]) > 0 else None


def fetch_latest_release() -> Optional[ReleaseInfo]:
    """Query GitHub API for the latest release. Returns None on error."""
    import json
    try:
        req = urllib.request.Request(
            _API_URL,
            headers={"Accept": "application/vnd.github+json",
                     "User-Agent": "Face-Local-Updater/1"},
        )
        with urllib.request.urlopen(req, timeout=8) as resp:
            data = json.loads(resp.read())
    except Exception as exc:
        log.warning("Update check failed: %s", exc)
        return None

    asset = _pick_asset(data.get("assets", []))
    if not asset:
        log.info("No matching asset found for platform %s", sys.platform)
        return None

    return ReleaseInfo(
        version=data["tag_name"].lstrip("v"),
        tag=data["tag_name"],
        url=data["html_url"],
        asset_name=asset["name"],
        asset_url=asset["browser_download_url"],
        asset_size=asset["size"],
    )


def is_newer(remote_version: str, local_version: str) -> bool:
    return _parse_version(remote_version) > _parse_version(local_version)


def download_asset(
    release: ReleaseInfo,
    progress_cb: Callable[[int, int], None],
) -> Path:
    """Download the release asset to a temp file. Returns the path.

    progress_cb(downloaded_bytes, total_bytes) is called periodically.
    """
    suffix = Path(release.asset_name).suffix
    tmp = tempfile.NamedTemporaryFile(
        delete=False, suffix=suffix, prefix="face-local-update-"
    )
    tmp.close()
    dest = Path(tmp.name)

    req = urllib.request.Request(
        release.asset_url,
        headers={"User-Agent": "Face-Local-Updater/1"},
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        total = release.asset_size or int(resp.headers.get("Content-Length") or 0)
        downloaded = 0
        chunk = 65536
        with open(dest, "wb") as fh:
            while True:
                buf = resp.read(chunk)
                if not buf:
                    break
                fh.write(buf)
                downloaded += len(buf)
                progress_cb(downloaded, total)

    log.info("Downloaded %s → %s", release.asset_name, dest)
    return dest


def apply_update(path: Path) -> None:
    """Open the downloaded installer / archive with the OS default handler."""
    import subprocess
    if sys.platform == "darwin":
        subprocess.Popen(["open", str(path)])
    elif sys.platform == "win32":
        import os
        os.startfile(str(path))
    else:
        subprocess.Popen(["xdg-open", str(path)])
