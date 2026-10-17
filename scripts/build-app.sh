#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "Building quicknote for macOS…"
swift build -c release

APP="dist/quicknote.app"
ICONSET="dist/quicknote.iconset"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" dist

cp ".build/release/quicknote" "$APP/Contents/MacOS/quicknote"

# Render the vector icon at all standard macOS icon sizes and bundle it as ICNS.
swift scripts/create-icon.swift Resources/AppIcon.svg "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

# Apply an ad-hoc signature so macOS can validate the app bundle's code.
# This is not an Apple Developer ID signature and does not notarize the app.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

# Create a drag-and-drop disk image installer.
mkdir -p dist/dmg-staging
cp -R "$APP" dist/dmg-staging/
ln -s /Applications dist/dmg-staging/Applications
hdiutil create \
  -volname "quicknote" \
  -srcfolder dist/dmg-staging \
  -ov -format UDZO \
  "dist/quicknote-macOS.dmg"
rm -rf dist/dmg-staging

echo "Created $APP and dist/quicknote-macOS.dmg"
