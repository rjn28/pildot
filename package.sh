#!/bin/bash

APP_NAME="BatteryIconApp"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"

# 1. Clean up previous build
rm -rf "$APP_BUNDLE" "$DMG_NAME"

# 2. Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.rjn28.$APP_NAME</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
</dict>
</plist>
EOF

# 4. Compile binary into the bundle
swiftc main.swift -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 5. Create DMG
# Create a temporary folder to layout the DMG contents
mkdir -p dist
cp -r "$APP_BUNDLE" dist/
ln -s /Applications dist/Applications

# Verify code signing (Ad-hoc signing to run locally)
# Required on Apple Silicon mostly, but good practice
codesign --force --deep --sign - "dist/$APP_BUNDLE"

hdiutil create -volname "$APP_NAME Installer" -srcfolder dist -ov -format UDZO "$DMG_NAME"

# Clean up
rm -rf dist

echo "Packaging complete: $DMG_NAME"
