#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building quicknote for macOS…"
swift build -c release

APP="dist/quicknote.app"
mkdir -p "$APP/Contents/MacOS"

cp ".build/release/quicknote" "$APP/Contents/MacOS/quicknote"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>quicknote</string>
    <key>CFBundleIdentifier</key>
    <string>com.waynetay.quicknote</string>
    <key>CFBundleName</key>
    <string>quicknote</string>
    <key>CFBundleDisplayName</key>
    <string>quicknote</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "Created $APP"
