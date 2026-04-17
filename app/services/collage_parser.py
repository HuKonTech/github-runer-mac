"""Picasa collage XML parser.

Supports both .cxf and .cfx file extensions (Picasa uses both names).
Parses the XML format produced by Google Picasa's collage feature and
returns a structured :class:`CollageData` object.

Path resolution
---------------
Picasa stores Windows-style paths like::

    [D]\\Képek\\nyár\\foto.jpg

On non-Windows systems these are mapped heuristically:

1. Try exact path (works on Wine / Windows).
2. Strip the ``[X]\\`` drive prefix and try relative to the collage file's
   directory.
3. Search sibling directories of the collage file for the filename.
4. If nothing works → mark ``src_missing=True`` but keep ``src_raw``.
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass, field
from pathlib import Path, PureWindowsPath
from typing import List, Optional
from xml.etree import ElementTree as ET

log = logging.getLogger(__name__)

# Regex: matches [X]\ or [X]/ at the start of a path (Picasa drive letters)
_DRIVE_PREFIX_RE = re.compile(r"^\[([A-Za-z])\][/\\]?", re.ASCII)


# ---------------------------------------------------------------------------
# Data containers (plain dataclasses – no SQLAlchemy dependency)
# ---------------------------------------------------------------------------

@dataclass
class CollageNodeData:
    """Data for a single <node> element."""
    node_uid: Optional[str] = None
    rel_x: float = 0.0
    rel_y: float = 0.0
    rel_w: float = 0.0
    rel_h: float = 0.0
    theta: float = 0.0
    scale: float = 100.0
    theme: Optional[str] = None
    src_raw: Optional[str] = None        # verbatim from XML
    src_resolved: Optional[str] = None  # absolute path on this system
    src_missing: bool = False


@dataclass
class CollageData:
    """Parsed representation of a full collage XML file."""
    source_file: str = ""
    collage_uid: Optional[str] = None
    format_width: Optional[int] = None
    format_height: Optional[int] = None
    orientation: Optional[str] = None
    album_title: Optional[str] = None
    album_date: Optional[str] = None
    bg_color: Optional[str] = None
    spacing: Optional[float] = None
    nodes: List[CollageNodeData] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

def parse_collage_file(
    file_path: str | Path,
    search_roots: Optional[List[str | Path]] = None,
) -> CollageData:
    """Parse a Picasa collage file (.cxf or .cfx).

    Args:
        file_path:    Path to the collage XML file.
        search_roots: Additional directory roots to search when resolving
                      ``[X]\\…`` paths.  The collage file's own directory is
                      always tried first.

    Returns:
        A :class:`CollageData` object.  Nodes with unresolvable paths have
        ``src_missing=True`` and ``src_resolved=None``.

    Raises:
        FileNotFoundError: If *file_path* does not exist.
        ET.ParseError:     If the XML is malformed beyond recovery.
    """
    file_path = Path(file_path)
    if not file_path.exists():
        raise FileNotFoundError(f"Collage file not found: {file_path}")

    log.info("Parsing collage: %s", file_path)

    try:
        tree = ET.parse(file_path)
    except ET.ParseError as exc:
        # Try to recover a partial tree
        log.warning("XML parse error in %s: %s — attempting recovery", file_path, exc)
        tree = _try_recover_xml(file_path)
        if tree is None:
            raise

    root = tree.getroot()
    data = CollageData(source_file=str(file_path))

    # --- collage attributes ---
    data.collage_uid = root.get("albumUID")
    data.orientation = root.get("orientation")

    fmt = root.get("format", "")
    if ":" in fmt:
        try:
            w_str, h_str = fmt.split(":", 1)
            data.format_width = int(w_str.strip())
            data.format_height = int(h_str.strip())
        except ValueError:
            log.debug("Cannot parse format=%r", fmt)

    # --- child elements ---
    for child in root:
        tag = child.tag.lower()
        if tag == "albumtitle":
            data.album_title = (child.text or "").strip() or None
        elif tag == "albumdate":
            data.album_date = (child.text or "").strip() or None
        elif tag == "background":
            data.bg_color = child.get("color")
        elif tag == "spacing":
            try:
                data.spacing = float(child.get("value", "0"))
            except ValueError:
                pass
        elif tag == "node":
            node = _parse_node(child, file_path, search_roots)
            data.nodes.append(node)

    log.info(
        "Collage parsed: %d node(s), %d missing source(s)",
        len(data.nodes),
        sum(1 for n in data.nodes if n.src_missing),
    )
    return data


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _parse_node(
    elem: ET.Element,
    collage_path: Path,
    search_roots: Optional[List[str | Path]],
) -> CollageNodeData:
    """Parse a single <node> XML element."""
    node = CollageNodeData()

    def _float(attr: str, default: float = 0.0) -> float:
        try:
            return float(elem.get(attr, default))
        except (ValueError, TypeError):
            return default

    node.rel_x = _float("x")
    node.rel_y = _float("y")
    node.rel_w = _float("w")
    node.rel_h = _float("h")
    node.theta = _float("theta")
    node.scale = _float("scale", 100.0)

    for child in elem:
        tag = child.tag.lower()
        if tag == "theme":
            node.theme = (child.text or "").strip() or None
        elif tag == "src":
            node.src_raw = (child.text or "").strip() or None
        elif tag == "uid":
            node.node_uid = (child.text or "").strip() or None

    # Resolve the source path
    if node.src_raw:
        resolved = _resolve_path(node.src_raw, collage_path, search_roots)
        if resolved is not None:
            node.src_resolved = str(resolved)
            node.src_missing = False
        else:
            node.src_resolved = None
            node.src_missing = True
            log.debug("Source not found: %r", node.src_raw)

    return node


def _resolve_path(
    raw: str,
    collage_path: Path,
    search_roots: Optional[List[str | Path]],
) -> Optional[Path]:
    """Attempt to resolve a (possibly Windows-style) path to an existing file.

    Strategy (in order):
    1. Try as a literal path (works on Windows / Wine).
    2. Strip ``[X]\\`` prefix and try relative to collage directory.
    3. Try common POSIX mount points (``/Volumes``, ``/mnt``, ``/media``).
    4. Try each supplied *search_roots*.
    5. Search only by filename in collage directory + search_roots.
    """
    # 1. Literal
    p = Path(raw)
    if p.exists():
        return p.resolve()

    # Normalise Windows separators → POSIX
    normalised = raw.replace("\\", "/")

    # Strip drive prefix like [D]/
    m = _DRIVE_PREFIX_RE.match(normalised)
    tail = _DRIVE_PREFIX_RE.sub("", normalised).lstrip("/") if m else normalised.lstrip("/")

    # 2. Relative to collage dir
    candidate = collage_path.parent / tail
    if candidate.exists():
        return candidate.resolve()

    # 3. Common mount roots
    for mount in ("/Volumes", "/mnt", "/media"):
        mp = Path(mount)
        if mp.is_dir():
            for sub in mp.iterdir():
                candidate = sub / tail
                if candidate.exists():
                    return candidate.resolve()

    # 4. Caller-supplied search roots
    for root in (search_roots or []):
        candidate = Path(root) / tail
        if candidate.exists():
            return candidate.resolve()

    # 5. Filename-only fallback
    filename = Path(tail).name
    if filename:
        dirs_to_search: List[Path] = [collage_path.parent]
        for root in (search_roots or []):
            dirs_to_search.append(Path(root))
        for d in dirs_to_search:
            if d.is_dir():
                for hit in d.rglob(filename):
                    if hit.is_file():
                        log.debug("Resolved by filename only: %s", hit)
                        return hit.resolve()

    return None


def _try_recover_xml(file_path: Path) -> Optional[ET.ElementTree]:
    """Read the file as text, strip any trailing junk, re-parse."""
    try:
        text = file_path.read_text(encoding="utf-8", errors="replace")
        # Find the last </collage> tag
        end = text.rfind("</collage>")
        if end != -1:
            text = text[: end + len("</collage>")]
        root = ET.fromstring(text)
        return ET.ElementTree(root)
    except Exception:
        return None


# ---------------------------------------------------------------------------
# Coordinate helpers (public utilities used by service + tests)
# ---------------------------------------------------------------------------

def project_face_to_collage(
    face_bbox: tuple[int, int, int, int],
    img_w: int,
    img_h: int,
    node: CollageNodeData,
    collage_w: int,
    collage_h: int,
) -> Optional[tuple[int, int, int, int]]:
    """Project a face bounding box from source image space to collage canvas space.

    Args:
        face_bbox:  (x, y, w, h) in the source image (pixels).
        img_w, img_h: Source image dimensions.
        node:       The CollageNode that contains this source image.
        collage_w, collage_h: Collage canvas dimensions in pixels.

    Returns:
        (px, py, pw, ph) in collage pixel space, or ``None`` if the face
        falls outside the visible node area.

    Notes:
        * When ``node.theta != 0`` the result is an approximation.
        * Picasa uses a *cover* (fill) strategy: the image is scaled so that
          both node dimensions are covered, then the zoom level (scale/100)
          is applied on top.
    """
    fx, fy, fw, fh = face_bbox

    # Node area in pixels
    nx = node.rel_x * collage_w
    ny = node.rel_y * collage_h
    nw = node.rel_w * collage_w
    nh = node.rel_h * collage_h

    if nw <= 0 or nh <= 0 or img_w <= 0 or img_h <= 0:
        return None

    # Cover scale: scale image to fill node box
    cover_scale = max(nw / img_w, nh / img_h)
    # Picasa zoom: scale=100 → exact cover; scale=133 → 33% extra zoom
    zoom = node.scale / 100.0
    effective_scale = cover_scale * zoom

    # Scaled image dimensions
    scaled_w = img_w * effective_scale
    scaled_h = img_h * effective_scale

    # Center crop: offset of the visible window into the scaled image
    crop_x = (scaled_w - nw) / 2.0
    crop_y = (scaled_h - nh) / 2.0

    # Map face bbox through the transform
    # face in source → face in scaled image → subtract crop → add node origin
    sfx = fx * effective_scale - crop_x
    sfy = fy * effective_scale - crop_y
    sfw = fw * effective_scale
    sfh = fh * effective_scale

    # Clip to node bounds
    clip_x1 = max(sfx, 0.0)
    clip_y1 = max(sfy, 0.0)
    clip_x2 = min(sfx + sfw, nw)
    clip_y2 = min(sfy + sfh, nh)

    if clip_x2 <= clip_x1 or clip_y2 <= clip_y1:
        return None  # face clipped entirely out of view

    out_x = int(nx + clip_x1)
    out_y = int(ny + clip_y1)
    out_w = int(clip_x2 - clip_x1)
    out_h = int(clip_y2 - clip_y1)

    return (out_x, out_y, out_w, out_h)
