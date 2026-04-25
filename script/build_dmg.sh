#!/usr/bin/env bash
set -euo pipefail

PRODUCT_NAME="GitHubRunnerMenu"
DISPLAY_NAME="github runer mac"
APP_VERSION="${APP_VERSION:-0.1.0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
RELEASE_DIR="$ROOT_DIR/release"
APP_BUNDLE="$DIST_DIR/$PRODUCT_NAME.app"
ARCH="$(uname -m)"
DMG_NAME="$PRODUCT_NAME-macOS-$ARCH-$APP_VERSION.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
STAGING_DIR="$DIST_DIR/dmg-staging"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "App bundle not found at $APP_BUNDLE" >&2
  echo "Run APP_VERSION=$APP_VERSION ./script/build_and_run.sh --bundle first." >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR" "$RELEASE_DIR"

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
/usr/bin/hdiutil create \
  -volname "$DISPLAY_NAME $APP_VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

/usr/bin/hdiutil verify "$DMG_PATH"

echo "$DMG_PATH"
