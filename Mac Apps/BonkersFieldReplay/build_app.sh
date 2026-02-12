#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

swift build -c release

APP_DIR="$ROOT/dist/BonkersFieldReplay.app/Contents"
mkdir -p "$APP_DIR/MacOS" "$APP_DIR/Resources"

cp ".build/release/BonkersFieldReplay" "$APP_DIR/MacOS/BonkersFieldReplay"

cat > "$APP_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>BonkersFieldReplay</string>
  <key>CFBundleIdentifier</key>
  <string>com.bonkers.fieldreplay</string>
  <key>CFBundleName</key>
  <string>BonkersFieldReplay</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

echo "Built $ROOT/dist/BonkersFieldReplay.app"
