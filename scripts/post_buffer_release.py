#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
import warnings
from typing import Iterable, List, Mapping, Sequence, Tuple


BUFFER_API_URL = "https://api.buffer.com"
DEFAULT_CHANNEL_SERVICE = "twitter"
DEFAULT_POST_MODE = "shareNow"
DEFAULT_SCHEDULING_TYPE = "automatic"
DEFAULT_USER_AGENT = "github-runer-mac-buffer-release/1.0"
MAX_POST_LENGTH = 280


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Publish a GitHub release announcement via Buffer.")
    parser.add_argument("--app-name", required=True)
    parser.add_argument("--tag", required=True)
    parser.add_argument("--release-url", required=True)
    parser.add_argument("--platform", action="append", default=[], metavar="NAME=RESULT")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def parse_platform(value: str) -> Tuple[str, str]:
    if "=" not in value:
        raise ValueError(f"Platform must be NAME=RESULT, got: {value}")
    name, result = value.split("=", 1)
    name = name.strip()
    result = result.strip()
    if not name or not result:
        raise ValueError(f"Platform must be NAME=RESULT, got: {value}")
    return name, result


def successful_platforms(platform_pairs: Iterable[Tuple[str, str]]) -> List[str]:
    return [name for name, result in platform_pairs if result.lower() == "success"]


def resolve_post_mode(env: Mapping[str, str] | None = None) -> str:
    source = env if env is not None else os.environ
    value = source.get("BUFFER_POST_MODE")
    if value is None or value.strip() == "":
        return DEFAULT_POST_MODE
    return value.strip()


def resolve_scheduling_type(env: Mapping[str, str] | None = None) -> str:
    source = env if env is not None else os.environ
    value = source.get("BUFFER_SCHEDULING_TYPE")
    if value is None or value.strip() == "":
        return DEFAULT_SCHEDULING_TYPE
    return value.strip()


def hashtagify_app_name(app_name: str) -> str:
    cleaned = "".join(character for character in app_name if character.isalnum())
    return f"#{cleaned}" if cleaned else "#Release"


def channel_sort_key(channel: Mapping[str, object]) -> Tuple[str, str, str]:
    display_name = str(channel.get("displayName") or channel.get("name") or "").lower()
    name = str(channel.get("name") or "").lower()
    channel_id = str(channel.get("id") or "")
    return (display_name, name, channel_id)


def select_channel(
    channels: Iterable[Mapping[str, object]],
    *,
    channel_id: str | None = None,
    channel_name: str | None = None,
    channel_service: str = DEFAULT_CHANNEL_SERVICE,
) -> Mapping[str, object]:
    channel_id = (channel_id or "").strip() or None
    channel_name = (channel_name or "").strip().lower() or None
    channel_service = (channel_service or DEFAULT_CHANNEL_SERVICE).strip().lower() or DEFAULT_CHANNEL_SERVICE

    ordered_channels = sorted(channels, key=channel_sort_key)

    if channel_id:
        for channel in ordered_channels:
            if str(channel.get("id")) == channel_id:
                return channel
        raise ValueError(f"Buffer channel '{channel_id}' was not found.")

    matching_channels = [
        channel
        for channel in ordered_channels
        if str(channel.get("service") or "").strip().lower() == channel_service
    ]

    if channel_name:
        matching_channels = [
            channel
            for channel in matching_channels
            if str(channel.get("displayName") or channel.get("name") or "").strip().lower() == channel_name
            or str(channel.get("name") or "").strip().lower() == channel_name
        ]

    if not matching_channels:
        label = channel_name or channel_service
        raise ValueError(f"No Buffer channel matched '{label}'.")

    if len(matching_channels) > 1:
        chosen = matching_channels[0]
        warnings.warn(
            "Multiple matching Buffer channels found; using the first deterministic match "
            f"({chosen.get('displayName') or chosen.get('name') or chosen.get('id')}).",
            stacklevel=2,
        )

    return matching_channels[0]


def render_post_text(
    app_name: str,
    tag: str,
    release_url: str,
    platforms: Sequence[str],
    *,
    template: str | None = None,
) -> str:
    platforms_text = ", ".join(platforms) if platforms else "macOS"
    hashtags = " ".join(
        [
            hashtagify_app_name(app_name),
            "#GitHubActions",
            "#SelfHostedRunner",
            "#macOSApp",
        ]
    )
    english_long = (
        "A lightweight macOS menu bar app to manage your local GitHub Actions self-hosted runner.\n\n"
        "Monitor status, control start/stop, and keep it running smoothly — all without opening Terminal."
    )
    hungarian_long = (
        "Egy könnyű macOS menüsor alkalmazás a helyi GitHub Actions self-hosted runner kezelésére.\n\n"
        "Figyelheted az állapotát, indíthatod/leállíthatod — mindezt Terminál nélkül."
    )
    english_short = "Manage your local GitHub Actions self-hosted runner from the macOS menu bar."
    hungarian_short = "A helyi GitHub Actions self-hosted runner kezelése a macOS menüsorból."

    if template:
        text = template.format(
            app_name=app_name,
            tag=tag,
            platforms=platforms_text,
            release_url=release_url,
            hashtags=hashtags,
        ).strip()
        if len(text) > MAX_POST_LENGTH:
            raise ValueError(f"Generated Buffer post exceeds {MAX_POST_LENGTH} characters.")
        return text

    opening = f"{app_name} {tag} is out. / Megjelent a {app_name} {tag}."
    compact_opening = f"{app_name} {tag}"
    platform_line = f"Platforms / Platformok: {platforms_text}."
    download_line = f"Download / Letöltés: {release_url}"

    candidates = [
        "\n\n".join([english_long, hungarian_long]),
        "\n\n".join([english_long, hungarian_long, download_line]),
        "\n\n".join([opening, english_long, hungarian_long, platform_line, download_line, hashtags]),
        "\n\n".join([compact_opening, english_short, hungarian_short, download_line]),
        "\n\n".join([compact_opening, english_short, hungarian_short, release_url]),
        "\n\n".join([opening, english_short, hungarian_short]),
        "\n\n".join([english_short, hungarian_short, download_line]),
        "\n\n".join([opening, english_short, hungarian_short, platform_line, download_line, hashtags]),
        "\n\n".join([opening, english_short, platform_line, download_line, hashtags]),
        "\n\n".join([opening, hungarian_short, platform_line, download_line, hashtags]),
        "\n\n".join([opening, platform_line, download_line, hashtags]),
        "\n\n".join([opening, download_line, hashtags]),
        "\n\n".join([opening, download_line, hashtagify_app_name(app_name), "#GitHubActions"]),
        "\n\n".join([opening, download_line]),
    ]

    for candidate in candidates:
        if len(candidate) <= MAX_POST_LENGTH:
            return candidate

    raise ValueError(f"Generated Buffer post exceeds {MAX_POST_LENGTH} characters.")


def resolve_user_agent(env: Mapping[str, str] | None = None) -> str:
    source = env if env is not None else os.environ
    value = source.get("BUFFER_USER_AGENT")
    if value is None or value.strip() == "":
        return DEFAULT_USER_AGENT
    return value.strip()


def format_http_error(error_code: int, details: str) -> str:
    cleaned = details.strip() or "No response body."
    if error_code == 403 and "1010" in cleaned:
        return (
            "Buffer API request failed (403). The response included `1010`, which likely means the "
            "request was blocked before normal GraphQL handling. This can happen when the API key is "
            "expired or lacks access to the target Buffer account/channel, or when edge protection "
            "rejects the default client signature. Regenerate the API key in "
            "https://publish.buffer.com/settings/api and, if possible, set BUFFER_CHANNEL_ID explicitly."
        )
    return f"Buffer API request failed ({error_code}): {cleaned}"


def graphql_request(api_key: str, query: str, variables: Mapping[str, object] | None = None) -> Mapping[str, object]:
    payload = json.dumps({"query": query, "variables": variables or {}}).encode("utf-8")
    request = urllib.request.Request(
        BUFFER_API_URL,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"Bearer {api_key}",
            "User-Agent": resolve_user_agent(),
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request) as response:
            raw_body = response.read()
    except urllib.error.HTTPError as error:
        details = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(format_http_error(error.code, details)) from error

    parsed = json.loads(raw_body.decode("utf-8"))
    errors = parsed.get("errors") or []
    if errors:
        messages = "; ".join(str(item.get("message", item)) for item in errors)
        raise RuntimeError(f"Buffer GraphQL error: {messages}")

    data = parsed.get("data")
    if not isinstance(data, dict):
        raise RuntimeError("Buffer API response did not include a data object.")
    return data


def discover_organization_ids(api_key: str, organization_id: str | None) -> List[str]:
    if organization_id:
        return [organization_id]

    data = graphql_request(
        api_key,
        """
        query GetOrganizations {
          account {
            organizations {
              id
            }
          }
        }
        """,
    )

    organizations = data.get("account", {}).get("organizations", [])
    ids = sorted(str(item.get("id")) for item in organizations if item.get("id"))
    if not ids:
        raise RuntimeError("No Buffer organizations are available for this API key.")
    return ids


def fetch_channels(api_key: str, organization_id: str) -> List[Mapping[str, object]]:
    data = graphql_request(
        api_key,
        """
        query GetChannels($organizationId: OrganizationId!) {
          channels(input: { organizationId: $organizationId }) {
            id
            name
            displayName
            service
          }
        }
        """,
        {"organizationId": organization_id},
    )
    channels = data.get("channels")
    if not isinstance(channels, list):
        raise RuntimeError("Buffer API did not return a channel list.")
    return channels


def resolve_channel(
    api_key: str,
    *,
    organization_id: str | None,
    channel_id: str | None,
    channel_name: str | None,
    channel_service: str,
) -> Mapping[str, object]:
    if channel_id:
        normalized_name = (channel_name or "").strip() or channel_id
        normalized_service = (channel_service or DEFAULT_CHANNEL_SERVICE).strip() or DEFAULT_CHANNEL_SERVICE
        return {
            "id": channel_id,
            "name": normalized_name,
            "displayName": normalized_name,
            "service": normalized_service,
        }

    organization_ids = discover_organization_ids(api_key, organization_id)
    collected_matches: List[Mapping[str, object]] = []

    for org_id in organization_ids:
        channels = fetch_channels(api_key, org_id)
        if channel_id:
            try:
                return select_channel(
                    channels,
                    channel_id=channel_id,
                    channel_name=channel_name,
                    channel_service=channel_service,
                )
            except ValueError:
                continue

        filtered = [
            channel
            for channel in channels
            if str(channel.get("service") or "").strip().lower() == channel_service.lower()
        ]
        if channel_name:
            name_lower = channel_name.strip().lower()
            filtered = [
                channel
                for channel in filtered
                if str(channel.get("displayName") or channel.get("name") or "").strip().lower() == name_lower
                or str(channel.get("name") or "").strip().lower() == name_lower
            ]
        collected_matches.extend(filtered)

    if not collected_matches:
        label = channel_id or channel_name or channel_service
        raise RuntimeError(f"No Buffer channel matched '{label}'.")

    return select_channel(
        collected_matches,
        channel_name=channel_name,
        channel_service=channel_service,
    )


def create_buffer_post(
    api_key: str,
    *,
    channel_id: str,
    text: str,
    mode: str,
    scheduling_type: str,
) -> Mapping[str, object]:
    data = graphql_request(
        api_key,
        """
        mutation CreatePost($input: CreatePostInput!) {
          createPost(input: $input) {
            ... on PostActionSuccess {
              post {
                id
                text
              }
            }
            ... on MutationError {
              message
            }
          }
        }
        """,
        {
            "input": {
                "channelId": channel_id,
                "text": text,
                "schedulingType": scheduling_type,
                "mode": mode,
                "source": "github-actions",
            }
        },
    )

    result = data.get("createPost")
    if not isinstance(result, dict):
        raise RuntimeError("Buffer createPost returned no result.")
    if result.get("message"):
        raise RuntimeError(f"Buffer rejected the post: {result['message']}")

    post = result.get("post")
    if not isinstance(post, dict):
        raise RuntimeError("Buffer createPost did not include a post payload.")
    return post


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    platform_pairs = [parse_platform(value) for value in args.platform]
    succeeded = successful_platforms(platform_pairs)
    template = (os.environ.get("BUFFER_POST_TEMPLATE") or "").strip() or None
    text = render_post_text(args.app_name, args.tag, args.release_url, succeeded, template=template)
    mode = resolve_post_mode()
    scheduling_type = resolve_scheduling_type()

    if args.dry_run:
        print(
            json.dumps(
                {
                    "mode": mode,
                    "schedulingType": scheduling_type,
                    "text": text,
                    "platforms": succeeded,
                },
                indent=2,
            )
        )
        return 0

    api_key = (os.environ.get("BUFFER_API_KEY") or "").strip()
    if not api_key:
        print("Skipping Buffer post because BUFFER_API_KEY is not configured.")
        return 0

    channel = resolve_channel(
        api_key,
        organization_id=(os.environ.get("BUFFER_ORGANIZATION_ID") or "").strip() or None,
        channel_id=(os.environ.get("BUFFER_CHANNEL_ID") or "").strip() or None,
        channel_name=(os.environ.get("BUFFER_CHANNEL_NAME") or "").strip() or None,
        channel_service=(os.environ.get("BUFFER_CHANNEL_SERVICE") or DEFAULT_CHANNEL_SERVICE).strip()
        or DEFAULT_CHANNEL_SERVICE,
    )

    post = create_buffer_post(
        api_key,
        channel_id=str(channel["id"]),
        text=text,
        mode=mode,
        scheduling_type=scheduling_type,
    )

    print(
        f"Posted release announcement via Buffer to "
        f"{channel.get('displayName') or channel.get('name') or channel.get('id')} "
        f"({channel.get('service')}). Post id: {post.get('id')}"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"Buffer release post failed: {error}", file=sys.stderr)
        raise SystemExit(1)
