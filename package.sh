#!/bin/bash

APP_NAME="BatteryIconApp"
APP_BUNDLE="$APP_NAME.app"
DMG_NAME="$APP_NAME.dmg"
ICON_SOURCE="logobatterie.png"
ICON_NAME="AppIcon"

# 1. Clean up previous build
rm -rf "$APP_BUNDLE" "$DMG_NAME" "dist" "$ICON_NAME.iconset"

# 2. Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Generate .icns if source image exists
if [ -f "$ICON_SOURCE" ]; then
    echo "Generating app icon from $ICON_SOURCE..."
    mkdir "$ICON_NAME.iconset"
    
    # Standard sizes
    sips -z 16 16     "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_16x16.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_32x32.png" > /dev/null
    sips -z 64 64     "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_128x128.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_256x256.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$ICON_SOURCE" --out "$ICON_NAME.iconset/icon_512x512@2x.png" > /dev/null

    iconutil -c icns "$ICON_NAME.iconset"
    mv "$ICON_NAME.icns" "$APP_BUNDLE/Contents/Resources/"
    rm -rf "$ICON_NAME.iconset"
    echo "Icon generated."
else
    echo "Warning: $ICON_SOURCE not found. App will use default icon."
fi

# 4. Create Info.plist
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
    <key>CFBundleIconFile</key>
    <string>$ICON_NAME</string>
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

# 5. Compile binary into the bundle
swiftc main.swift -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# 6. Create DMG
# Create a temporary folder to layout the DMG contents
mkdir -p dist
cp -r "$APP_BUNDLE" dist/
ln -s /Applications dist/Applications

# Verify code signing (Ad-hoc signing to run locally)
codesign --force --deep --sign - "dist/$APP_BUNDLE"

hdiutil create -volname "$APP_NAME Installer" -srcfolder dist -ov -format UDZO "$DMG_NAME"

# Clean up
rm -rf dist

echo "Packaging complete: $DMG_NAME"
