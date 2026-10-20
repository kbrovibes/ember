#!/bin/bash
# Builds Ember and assembles build/Ember.app (ad-hoc signed).
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh

CONFIG="${1:-release}"
swift build -c "$CONFIG" 2>&1 | grep -v -E "ld: warning|arclite" || true
BIN="$(swift build -c "$CONFIG" --show-bin-path 2>/dev/null)/Ember"
[ -x "$BIN" ] || { echo "build failed: $BIN missing" >&2; exit 1; }

APP="build/Ember.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Ember"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Ember</string>
  <key>CFBundleDisplayName</key><string>Ember</string>
  <key>CFBundleIdentifier</key><string>app.ember.timer</string>
  <key>CFBundleExecutable</key><string>Ember</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || echo "warning: codesign failed (app may still run locally)" >&2
echo "built $APP"
