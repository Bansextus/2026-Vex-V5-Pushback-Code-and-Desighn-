#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

swift build -c release

APP_DIR="$ROOT_DIR/build/Tahera.app/Contents"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

cp "$ROOT_DIR/.build/release/Tahera" "$APP_DIR/MacOS/Tahera"
cp "$ROOT_DIR/Info.plist" "$APP_DIR/Info.plist"

for bundle in "$ROOT_DIR/.build/release"/*.bundle "$ROOT_DIR/.build/arm64-apple-macosx/release"/*.bundle; do
  if [ -e "$bundle" ]; then
    cp -R "$bundle" "$APP_DIR/Resources/"
  fi
done

ICON_SRC="$ROOT_DIR/Sources/Tahera/Resources/tahera_logo.png"
ICONSET_DIR="$ROOT_DIR/build/AppIcon.iconset"
ICNS_OUT="$ROOT_DIR/build/AppIcon.icns"

if [ -f "$ICON_SRC" ]; then
  rm -rf "$ICONSET_DIR"
  mkdir -p "$ICONSET_DIR"
  sips -z 16 16 "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
  sips -z 32 32 "$ICON_SRC" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
  sips -z 64 64 "$ICON_SRC" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
  sips -z 256 256 "$ICON_SRC" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
  sips -z 512 512 "$ICON_SRC" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$ICONSET_DIR" -o "$ICNS_OUT"
  cp "$ICNS_OUT" "$APP_DIR/Resources/AppIcon.icns"
fi

echo "Built $ROOT_DIR/build/Tahera.app"
