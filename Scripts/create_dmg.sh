#!/bin/bash
set -e

APP_NAME="Buatsaver"

# Get the script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Read version from VERSION file
if [ -f "VERSION" ]; then
    VERSION=$(cat VERSION)
else
    echo "Error: VERSION file not found"
    exit 1
fi

DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_TEMP="${APP_NAME}-temp.dmg"
APP_PATH="build/Release/Buatsaver.app"

echo "📦 Creating DMG for $APP_NAME v$VERSION..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found. Run ./Scripts/build.sh first."
    exit 1
fi

# Create temporary directory
TMP_DIR="dmg_temp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR/.background"

# Copy app to temp directory
echo "Copying $APP_NAME.app..."
cp -r "$APP_PATH" "$TMP_DIR/"

# Create symlink to Applications folder
echo "Creating Applications symlink..."
ln -s /Applications "$TMP_DIR/Applications"

# Create a README for users
cat > "$TMP_DIR/README.txt" <<EOF
Buatsaver v$VERSION

INSTALLATION:
1. Drag Buatsaver.app to the Applications folder
2. Right-click on Buatsaver.app and select "Open" (first time only)
3. Click "Open" in the security dialog

USAGE:
1. Launch Buatsaver
2. Select your video file (or drag and drop)
3. Enter a name for your screensaver
4. Click "Generate Screensaver"
5. Double-click the generated .saver file to install

For more information, visit:
https://github.com/zetkey/Buatsaver

Note: This app is unsigned. macOS will show a security warning on first launch.
This is normal for apps distributed outside the App Store.
EOF

# Create temporary DMG
echo "Creating temporary DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TMP_DIR" \
    -ov -format UDRW \
    "$DMG_TEMP"

# Mount the temporary DMG
echo "Mounting DMG..."
MOUNT_DIR=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | grep Volumes | sed 's/.*\/Volumes\//\/Volumes\//')

# Wait for mount
sleep 2

# Customize DMG appearance with AppleScript
echo "Customizing DMG appearance..."
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 612, 512}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 110
        set position of item "$APP_NAME.app" of container window to {100, 100}
        set position of item "Applications" of container window to {400, 100}
        set position of item "README.txt" of container window to {250, 300}

        update without registering applications
    end tell
end tell
EOF

# Unmount
echo "Finalizing DMG..."
hdiutil detach "$MOUNT_DIR"

# Convert to compressed read-only DMG
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_NAME"

# Cleanup
rm -rf "$TMP_DIR" "$DMG_TEMP"

echo "✅ Created $DMG_NAME in project root"
echo ""
echo "Next steps:"
echo "1. Test the DMG by mounting it: open $DMG_NAME"
echo "2. Create a GitHub release: gh release create v$VERSION $DMG_NAME"
