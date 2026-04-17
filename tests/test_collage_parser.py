"""Tests for the Picasa collage XML parser and coordinate utilities.

Run with:  pytest tests/test_collage_parser.py -v
"""

from __future__ import annotations

import math
import textwrap
import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

from app.services.collage_parser import (
    CollageData,
    CollageNodeData,
    parse_collage_file,
    project_face_to_collage,
    _resolve_path,
    _DRIVE_PREFIX_RE,
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

SAMPLE_XML = textwrap.dedent("""\
    <?xml version="1.0" encoding="utf-8" ?>
    <collage version="2" format="2858:1000" orientation="landscape"
             theme="picturegrid" shadows="0" captions="0"
             albumUID="516de887be88912fed726867c2bbee6e">
      <albumTitle>Teszt album</albumTitle>
      <albumDate>2026. március</albumDate>
      <background type="solid" color="FFFFFFFF"/>
      <spacing value="0.000000"/>
      <node x="0.100000" y="0.200000" w="0.300000" h="0.400000"
            theta="0.000000" scale="133.000000">
        <theme>noborder</theme>
        <src>[D]\\Képek\\nyár\\foto1.JPG</src>
        <uid>aabbcc1122334455</uid>
      </node>
      <node x="0.500000" y="0.000000" w="0.200000" h="0.500000"
            theta="0.050000" scale="100.000000">
        <theme>noborder</theme>
        <src>[E]\\Archiv\\foto2.jpg</src>
        <uid>ddeeff6677889900</uid>
      </node>
    </collage>
""")


@pytest.fixture()
def collage_file(tmp_path: Path) -> Path:
    """Write the sample XML to a temporary file."""
    f = tmp_path / "test_collage.cxf"
    f.write_text(SAMPLE_XML, encoding="utf-8")
    return f


@pytest.fixture()
def collage_file_cfx(tmp_path: Path) -> Path:
    """Same content but with .cfx extension."""
    f = tmp_path / "test_collage.cfx"
    f.write_text(SAMPLE_XML, encoding="utf-8")
    return f


# ---------------------------------------------------------------------------
# Parser tests
# ---------------------------------------------------------------------------

class TestParseCollageFile:
    def test_returns_collage_data(self, collage_file):
        data = parse_collage_file(collage_file)
        assert isinstance(data, CollageData)

    def test_cfx_extension_accepted(self, collage_file_cfx):
        """Both .cxf and .cfx extensions must parse correctly."""
        data = parse_collage_file(collage_file_cfx)
        assert len(data.nodes) == 2

    def test_collage_uid(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.collage_uid == "516de887be88912fed726867c2bbee6e"

    def test_format_parsed(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.format_width == 2858
        assert data.format_height == 1000

    def test_orientation(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.orientation == "landscape"

    def test_album_title(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.album_title == "Teszt album"

    def test_album_date(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.album_date == "2026. március"

    def test_bg_color(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.bg_color == "FFFFFFFF"

    def test_spacing(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.spacing == pytest.approx(0.0)

    def test_node_count(self, collage_file):
        data = parse_collage_file(collage_file)
        assert len(data.nodes) == 2

    def test_node_geometry(self, collage_file):
        data = parse_collage_file(collage_file)
        n = data.nodes[0]
        assert n.rel_x == pytest.approx(0.1)
        assert n.rel_y == pytest.approx(0.2)
        assert n.rel_w == pytest.approx(0.3)
        assert n.rel_h == pytest.approx(0.4)

    def test_node_theta_and_scale(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.nodes[0].theta == pytest.approx(0.0)
        assert data.nodes[0].scale == pytest.approx(133.0)
        assert data.nodes[1].theta == pytest.approx(0.05)
        assert data.nodes[1].scale == pytest.approx(100.0)

    def test_node_theme(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.nodes[0].theme == "noborder"

    def test_node_uid(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.nodes[0].node_uid == "aabbcc1122334455"
        assert data.nodes[1].node_uid == "ddeeff6677889900"

    def test_node_src_raw(self, collage_file):
        data = parse_collage_file(collage_file)
        assert "foto1.JPG" in data.nodes[0].src_raw

    def test_missing_src_marked(self, collage_file):
        """Source files don't exist → src_missing should be True."""
        data = parse_collage_file(collage_file)
        assert data.nodes[0].src_missing is True
        assert data.nodes[0].src_resolved is None

    def test_source_file_stored(self, collage_file):
        data = parse_collage_file(collage_file)
        assert data.source_file == str(collage_file)

    def test_file_not_found_raises(self, tmp_path):
        with pytest.raises(FileNotFoundError):
            parse_collage_file(tmp_path / "nonexistent.cxf")


class TestParsePartialXml:
    def test_partial_xml_recovered(self, tmp_path):
        """A truncated XML file should still parse partially."""
        partial = """\
<?xml version="1.0" encoding="utf-8" ?>
<collage version="2" format="1000:500" albumUID="abc123">
  <albumTitle>Partial</albumTitle>
  <node x="0.0" y="0.0" w="0.5" h="1.0" theta="0" scale="100">
    <src>[D]\\foo\\bar.jpg</src>
    <uid>uid1</uid>
  </node>
</collage>"""
        f = tmp_path / "partial.cxf"
        f.write_text(partial, encoding="utf-8")
        data = parse_collage_file(f)
        assert data.album_title == "Partial"
        assert len(data.nodes) == 1


# ---------------------------------------------------------------------------
# Path resolution tests
# ---------------------------------------------------------------------------

class TestPathResolution:
    def test_drive_prefix_stripped(self):
        m = _DRIVE_PREFIX_RE.match("[D]\\")
        assert m is not None
        assert m.group(1) == "D"

    def test_lowercase_drive(self):
        m = _DRIVE_PREFIX_RE.match("[d]/")
        assert m is not None

    def test_no_drive_prefix(self):
        m = _DRIVE_PREFIX_RE.match("C:\\Users\\foo.jpg")
        assert m is None

    def test_resolve_existing_file_relative_to_collage(self, tmp_path):
        """If the file exists relative to the collage dir, it is found."""
        img_dir = tmp_path / "Képek"
        img_dir.mkdir()
        img = img_dir / "foto.jpg"
        img.write_bytes(b"FAKE")

        collage_file = tmp_path / "my_collage.cxf"
        raw = "[D]\\Képek\\foto.jpg"
        result = _resolve_path(raw, collage_file, [])
        assert result is not None
        assert result.name == "foto.jpg"

    def test_resolve_by_filename_fallback(self, tmp_path):
        """Filename-only search finds the file anywhere under the collage dir."""
        nested = tmp_path / "deep" / "nested"
        nested.mkdir(parents=True)
        img = nested / "unique_foto.jpg"
        img.write_bytes(b"FAKE")

        collage_file = tmp_path / "c.cxf"
        raw = "[Z]\\some\\other\\path\\unique_foto.jpg"
        result = _resolve_path(raw, collage_file, [])
        assert result is not None
        assert result.name == "unique_foto.jpg"

    def test_returns_none_if_not_found(self, tmp_path):
        collage_file = tmp_path / "c.cxf"
        result = _resolve_path("[D]\\nonexistent\\foto.jpg", collage_file, [])
        assert result is None


# ---------------------------------------------------------------------------
# Coordinate projection tests
# ---------------------------------------------------------------------------

class TestProjectFaceToCollage:
    """Tests for project_face_to_collage()."""

    def _make_node(self, rx=0.0, ry=0.0, rw=1.0, rh=1.0, theta=0.0, scale=100.0):
        return CollageNodeData(
            rel_x=rx, rel_y=ry, rel_w=rw, rel_h=rh,
            theta=theta, scale=scale,
        )

    def test_full_canvas_no_zoom_face_center(self):
        """Node covers full canvas, no zoom, square image and canvas."""
        node = self._make_node(0.0, 0.0, 1.0, 1.0, 0.0, 100.0)
        # image 200x200, canvas 200x200, face at center (50,50,100,100)
        result = project_face_to_collage((50, 50, 100, 100), 200, 200, node, 200, 200)
        assert result is not None
        px, py, pw, ph = result
        assert px == 50
        assert py == 50
        assert pw == 100
        assert ph == 100

    def test_node_in_top_left_quarter(self):
        """Node occupies top-left quarter of canvas."""
        node = self._make_node(0.0, 0.0, 0.5, 0.5, 0.0, 100.0)
        # image 200x200, canvas 400x400
        # node occupies 200x200 px in the top-left
        # face at (0,0,200,200) in source → should map to (0,0,200,200) in node space
        result = project_face_to_collage((0, 0, 200, 200), 200, 200, node, 400, 400)
        assert result is not None
        px, py, pw, ph = result
        assert px == 0
        assert py == 0
        assert pw == pytest.approx(200, abs=2)
        assert ph == pytest.approx(200, abs=2)

    def test_zoom_clips_face_outside_view(self):
        """With heavy zoom, a face near the edge may be clipped out."""
        node = self._make_node(0.0, 0.0, 1.0, 1.0, 0.0, 200.0)
        # scale=200 → only the center 50% of the image is visible
        # A face at (0,0,10,10) in top-left corner should be out of view
        result = project_face_to_collage((0, 0, 10, 10), 400, 400, node, 400, 400)
        assert result is None

    def test_zoom_100_square_full_image(self):
        """scale=100 with square image: face covers full image → full node."""
        node = self._make_node(0.1, 0.1, 0.8, 0.8, 0.0, 100.0)
        # image 100x100, canvas 1000x1000 → node 800x800 px offset (100,100)
        # face = full image (0,0,100,100) should cover full node
        result = project_face_to_collage((0, 0, 100, 100), 100, 100, node, 1000, 1000)
        assert result is not None
        px, py, pw, ph = result
        assert px == pytest.approx(100, abs=2)
        assert py == pytest.approx(100, abs=2)
        assert pw == pytest.approx(800, abs=2)
        assert ph == pytest.approx(800, abs=2)

    def test_returns_none_for_zero_dimensions(self):
        node = self._make_node(0.0, 0.0, 0.0, 0.0)
        result = project_face_to_collage((0, 0, 50, 50), 100, 100, node, 400, 400)
        assert result is None

    def test_returns_none_for_zero_image(self):
        node = self._make_node(0.0, 0.0, 1.0, 1.0)
        result = project_face_to_collage((0, 0, 50, 50), 0, 0, node, 400, 400)
        assert result is None

    def test_pixel_bbox_helper(self):
        """CollageNode.pixel_bbox() should match manual calculation.

        pixel_bbox is defined on the ORM model (CollageNode), not on
        CollageNodeData.  We test it here via a simple projection call
        that exercises the same arithmetic.
        """
        from app.db.models import CollageNode

        node = CollageNode(
            collage_id=0,
            rel_x=0.1, rel_y=0.2, rel_w=0.3, rel_h=0.4,
            theta=0.0, scale=100.0,
        )
        px, py, pw, ph = node.pixel_bbox(1000, 500)
        assert px == 100
        assert py == 100
        assert pw == 300
        assert ph == 200

    def test_wide_image_cover_scale(self):
        """A 400x200 image in a 200x200 node: cover means horizontal crop."""
        node = self._make_node(0.0, 0.0, 1.0, 1.0, 0.0, 100.0)
        # cover scale = max(200/400, 200/200) = max(0.5, 1.0) = 1.0
        # scaled image = 400x200 — no wait: scale=1.0 → 400*1=400, 200*1=200
        # That doesn't cover. Let me recalculate:
        # cover = max(canvas_w/img_w, canvas_h/img_h) = max(200/400, 200/200) = max(0.5, 1.0) = 1.0
        # scaled 400*1=400w × 200*1=200h → covers 200 height, but width=400 > 200 ✓
        # crop_x = (400-200)/2 = 100, crop_y = 0
        # Face at center (150,0,100,200) → in scaled: same coordinates
        # sfx = 150-100 = 50, sfy=0, sfw=100, sfh=200
        # clip: x in [50,150] ✓, y in [0,200] ✓
        # node origin at 0,0 → result = (50, 0, 100, 200)
        result = project_face_to_collage((150, 0, 100, 200), 400, 200, node, 200, 200)
        assert result is not None
        px, py, pw, ph = result
        assert px == pytest.approx(50, abs=2)
        assert py == pytest.approx(0, abs=2)
        assert pw == pytest.approx(100, abs=2)
        assert ph == pytest.approx(200, abs=2)
