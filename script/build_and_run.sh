#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
PRODUCT_NAME="GitHubRunnerMenu"
DISPLAY_NAME="github runer mac"
BUNDLE_ID="com.koncsik.githubrunnermenu"
MIN_SYSTEM_VERSION="14.0"
APP_VERSION="${APP_VERSION:-0.1.0}"
CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}"
BUILD_CONFIGURATION="${BUILD_CONFIGURATION:-debug}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$PRODUCT_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$PRODUCT_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ICON_FILE="$ROOT_DIR/Assets/AppIcon.icns"

pkill -x "$PRODUCT_NAME" >/dev/null 2>&1 || true

swift build --package-path "$ROOT_DIR" -c "$BUILD_CONFIGURATION"
BUILD_BINARY="$(swift build --package-path "$ROOT_DIR" -c "$BUILD_CONFIGURATION" --show-bin-path)/$PRODUCT_NAME"
/usr/bin/swift "$ROOT_DIR/script/generate_icon.swift" >/dev/null
/usr/bin/iconutil -c icns "$ROOT_DIR/Assets/AppIcon.iconset" -o "$ICON_FILE"

rm -rf "$DIST_DIR"/*.app
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
cp "$ICON_FILE" "$APP_RESOURCES/AppIcon.icns"
chmod +x "$APP_BINARY"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$PRODUCT_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$DISPLAY_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

codesign_args=(--force --deep --sign "$CODE_SIGN_IDENTITY")
if [[ "$CODE_SIGN_IDENTITY" != "-" ]]; then
  codesign_args+=(--options runtime --timestamp)
fi

/usr/bin/codesign "${codesign_args[@]}" "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  --bundle|bundle)
    ;;
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$PRODUCT_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$PRODUCT_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--bundle|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
