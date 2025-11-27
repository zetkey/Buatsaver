#!/bin/bash
set -e

echo "🚀 Starting Full Build..."

# 1. Build the Template Screensaver (Objective-C)
echo "🛠️  Building Template Screensaver..."
xcodebuild -project Buatsaver.xcodeproj \
  -scheme Buatsaver \
  -configuration Release \
  CONFIGURATION_BUILD_DIR="./build/Release" \
  build

# 2. Copy the built saver to the App's resource directory
echo "📂 Copying Template to App Resources..."
APP_RESOURCE_DIR="BuatsaverApp/Sources/BuatsaverApp/Resources"
mkdir -p "$APP_RESOURCE_DIR"
rm -rf "$APP_RESOURCE_DIR/Buatsaver.saver"
cp -r "build/Release/Buatsaver.saver" "$APP_RESOURCE_DIR/Buatsaver.saver"

# 3. Build the Builder App (Swift)
echo "🛠️  Building Builder App..."
cd BuatsaverApp
swift build -c release

# 4. Bundle the App
echo "📦 Bundling App..."
./bundle_app.sh

echo "✅ Build Complete!"
echo "Find your app at: BuatsaverApp/Buatsaver.app"
