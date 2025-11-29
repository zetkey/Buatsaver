#!/bin/bash
set -e

echo "🚀 Building Buatsaver..."

# Get the project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

# Read version
VERSION=$(cat VERSION 2>/dev/null || echo "1.0.0")
echo "📦 Version: $VERSION"

# Create build directory
BUILD_DIR="$PROJECT_ROOT/build/Release"
mkdir -p "$BUILD_DIR"

# Step 1: Build the Screensaver Bundle
echo ""
echo "🛠️  Building Screensaver Bundle..."

SAVER_NAME="BuatsaverScreensaver"
SAVER_BUNDLE="$BUILD_DIR/$SAVER_NAME.saver"
SAVER_CONTENTS="$SAVER_BUNDLE/Contents"
SAVER_MACOS="$SAVER_CONTENTS/MacOS"
SAVER_RESOURCES="$SAVER_CONTENTS/Resources"

# Clean and create bundle structure
rm -rf "$SAVER_BUNDLE"
mkdir -p "$SAVER_MACOS"
mkdir -p "$SAVER_RESOURCES"

# Compile the screensaver as a dynamic library
swiftc \
    -target x86_64-apple-macos12.0 \
    -emit-library \
    -module-name BuatsaverScreensaver \
    -framework ScreenSaver \
    -framework AVFoundation \
    -framework AVKit \
    -framework Cocoa \
    -Xlinker -install_name -Xlinker @executable_path/../Frameworks/BuatsaverScreensaver.framework/Versions/A/BuatsaverScreensaver \
    -o "$SAVER_MACOS/$SAVER_NAME" \
    "$PROJECT_ROOT/BuatsaverScreensaver/Sources/BuatsaverView.swift"

# Copy Info.plist
cp "$PROJECT_ROOT/BuatsaverScreensaver/Info.plist" "$SAVER_CONTENTS/Info.plist"

# Update version in Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$SAVER_CONTENTS/Info.plist" 2>/dev/null || true

echo "✅ Screensaver bundle created at: $SAVER_BUNDLE"

# Step 2: Build the App
echo ""
echo "🛠️  Building Application..."

APP_NAME="Buatsaver"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"

# Clean and create app bundle structure
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS"
mkdir -p "$APP_RESOURCES"

# Compile the app
swiftc \
    -target x86_64-apple-macos12.0 \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    -framework UniformTypeIdentifiers \
    -emit-executable \
    -o "$APP_MACOS/BuatsaverApp" \
    "$PROJECT_ROOT/BuatsaverApp/Sources/BuatsaverApp.swift" \
    "$PROJECT_ROOT/BuatsaverApp/Sources/ContentView.swift" \
    "$PROJECT_ROOT/BuatsaverApp/Sources/SaverGenerator.swift" \
    "$PROJECT_ROOT/BuatsaverApp/Sources/Components/FileDropZone.swift" \
    "$PROJECT_ROOT/BuatsaverApp/Sources/Components/ModernButton.swift" \
    "$PROJECT_ROOT/BuatsaverApp/Sources/Components/ModernTextField.swift"

# Copy Info.plist
cp "$PROJECT_ROOT/BuatsaverApp/Info.plist" "$APP_CONTENTS/Info.plist"

# Update version in Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_CONTENTS/Info.plist" 2>/dev/null || true

# Copy app icon if it exists
if [ -f "$PROJECT_ROOT/BuatsaverApp/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/BuatsaverApp/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
elif [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
fi

# Copy Swift source file for runtime compilation
cp "$PROJECT_ROOT/BuatsaverScreensaver/Sources/BuatsaverView.swift" "$APP_RESOURCES/BuatsaverView.swift"

echo "✅ Application bundle created at: $APP_BUNDLE"

# Step 3: Code signing (ad-hoc for local use)
echo ""
echo "🔏 Code signing..."
codesign --force --deep --sign - "$SAVER_BUNDLE" 2>/dev/null || echo "⚠️  Screensaver signing skipped"
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || echo "⚠️  App signing skipped"

echo ""
echo "✅ Build Complete!"
echo "📍 App location: $APP_BUNDLE"
echo ""
echo "To test the app:"
echo "  open $APP_BUNDLE"
