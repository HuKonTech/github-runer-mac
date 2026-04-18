from __future__ import annotations

import importlib.util
import pathlib
import warnings


SCRIPT_PATH = pathlib.Path(__file__).resolve().parents[1] / "scripts" / "post_buffer_release.py"
SPEC = importlib.util.spec_from_file_location("post_buffer_release", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


def test_render_post_text_stays_within_limit():
    text = MODULE.render_post_text(
        "ExampleApp",
        "v1.2.3",
        "https://github.com/org/repo/releases/tag/v1.2.3",
        ["macOS", "Windows"],
    )

    assert "ExampleApp v1.2.3 is out." in text
    assert "Megjelent a ExampleApp v1.2.3." in text
    assert "Manage your local GitHub Actions self-hosted runner from the macOS menu bar." in text
    assert "A helyi GitHub Actions self-hosted runner kezelése a macOS menüsorból." in text
    assert len(text) <= 280


def test_select_channel_uses_first_deterministic_match():
    channels = [
        {"id": "3", "displayName": "Zulu", "name": "zulu", "service": "twitter"},
        {"id": "1", "displayName": "Alpha", "name": "alpha", "service": "twitter"},
        {"id": "2", "displayName": "Mastodon", "name": "mastodon", "service": "mastodon"},
    ]

    with warnings.catch_warnings(record=True) as captured:
        warnings.simplefilter("always")
        selected = MODULE.select_channel(channels, channel_service="twitter")

    assert selected["id"] == "1"
    assert captured
    assert "Multiple matching Buffer channels found" in str(captured[0].message)


def test_empty_buffer_post_mode_falls_back_to_share_now():
    assert MODULE.resolve_post_mode({"BUFFER_POST_MODE": ""}) == "shareNow"


def test_empty_buffer_scheduling_type_falls_back_to_automatic():
    assert MODULE.resolve_scheduling_type({"BUFFER_SCHEDULING_TYPE": ""}) == "automatic"


def test_resolve_channel_short_circuits_for_explicit_channel_id():
    selected = MODULE.resolve_channel(
        "token",
        organization_id=None,
        channel_id="channel-123",
        channel_name="X account",
        channel_service="twitter",
    )

    assert selected == {
        "id": "channel-123",
        "name": "X account",
        "displayName": "X account",
        "service": "twitter",
    }


def test_format_http_error_for_1010_is_actionable():
    message = MODULE.format_http_error(403, "error code: 1010")

    assert "blocked before normal GraphQL handling" in message
    assert "BUFFER_CHANNEL_ID" in message
