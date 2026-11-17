#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
APP="$(pwd)/build/LidToggle.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/LidToggle" "$APP/Contents/MacOS/LidToggle"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/LidToggle.icns "$APP/Contents/Resources/LidToggle.icns"
codesign --force --sign - "$APP"
echo "App built: $APP"
