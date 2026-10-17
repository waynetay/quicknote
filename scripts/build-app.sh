#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building Notepad for macOS…"
swift build -c release

APP="dist/Notepad.app"
mkdir -p "$APP/Contents/MacOS"

cp ".build/release/Notepad" "$APP/Contents/MacOS/Notepad"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Notepad</string>
    <key>CFBundleIdentifier</key>
    <string>com.waynetay.notepad</string>
    <key>CFBundleName</key>
    <string>Notepad</string>
    <key>CFBundleDisplayName</key>
    <string>Notepad</string>
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
