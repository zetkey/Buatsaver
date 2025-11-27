#!/bin/bash
set -e

APP_NAME="Buatsaver"
EXECUTABLE="BuatsaverApp"
OUTPUT_DIR="."

# Read version from VERSION file
if [ -f "../VERSION" ]; then
    VERSION=$(cat ../VERSION)
else
    VERSION="1.0.0"
fi

# Auto-detect build directory (prefer release, fallback to debug)
if [ -d ".build/release" ]; then
    BUILD_DIR=".build/release"
elif [ -d ".build/debug" ]; then
    BUILD_DIR=".build/debug"
else
    echo "Error: No build directory found. Run 'swift build' first."
    exit 1
fi

echo "Creating $APP_NAME.app..."
echo "Version: $VERSION"
echo "Using build from: $BUILD_DIR"

# Create directory structure
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources"

# Copy executable
cp "$BUILD_DIR/$EXECUTABLE" "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"

# Copy app icon if it exists
APP_ICON_PATH="./AppIcon.icns"
if [ -f "$APP_ICON_PATH" ]; then
    echo "Copying app icon..."
    cp "$APP_ICON_PATH" "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/$APP_NAME.icns"
fi

# Copy resources (SwiftPM puts them in a bundle directory next to the binary)
# The bundle name is usually PackageName_TargetName.bundle
RESOURCE_BUNDLE="$BUILD_DIR/${EXECUTABLE}_${EXECUTABLE}.bundle"

if [ -d "$RESOURCE_BUNDLE" ]; then
    echo "Copying resources from $RESOURCE_BUNDLE..."
    cp -r "$RESOURCE_BUNDLE" "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/"
else
    echo "Warning: Resource bundle not found at $RESOURCE_BUNDLE"
fi

# Create Info.plist
cat > "$OUTPUT_DIR/$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>id.my.zetkey.buatsaver</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>CFBundleIconFile</key>
    <string>$APP_NAME.icns</string>
</dict>
</plist>
EOF

echo "$APP_NAME.app created successfully at $OUTPUT_DIR/$APP_NAME.app"
