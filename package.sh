#!/usr/bin/env bash
set -euo pipefail

APP_NAME="BatteryIconApp"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="${BATTERY_ICON_DMG_PATH:-$ROOT_DIR/$APP_NAME.dmg}"
DMG_STAGING="$ROOT_DIR/.build/dmg-staging"

"$ROOT_DIR/script/build_app_bundle.sh" release

rm -rf -- "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create \
  -volname "$APP_NAME Installer" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf -- "$DMG_STAGING"
echo "Installateur créé : $DMG_PATH"
