# Buatsaver

A macOS application that converts video files into native screensavers.

## Features

- **Video Support**: Works with `.mp4` and `.mov` files
- **Auto-Thumbnail**: Automatically generates a thumbnail from your video
- **Custom Icons**: Sets the generated screensaver's icon to the thumbnail
- **Smart Bundle IDs**: Automatically generates clean bundle identifiers
- **Native Performance**: Built with SwiftUI and Objective-C

## Installation

### For Users

1. Download the latest `Buatsaver-x.x.x.dmg` from [Releases](https://github.com/zetkey/Buatsaver/releases)
2. Open the DMG file
3. Drag `Buatsaver.app` to your Applications folder
4. **Important**: Right-click on `Buatsaver.app` and select "Open" (first time only)
5. Click "Open" in the security dialog

> **Note**: This app is unsigned. macOS will show a security warning on first launch. This is normal for apps distributed outside the App Store.

### Alternative: Remove Quarantine Flag

If you prefer, you can remove the quarantine flag:

```bash
xattr -cr /Applications/Buatsaver.app
```

## Usage

1. Launch `Buatsaver.app`
2. Click **Choose Video** and select your video file
3. (Optional) Customize the thumbnail by clicking **Choose Image**
4. Enter a name for your screensaver
5. Click **Generate .saver**
6. Double-click the generated `.saver` file to install

The screensaver will appear in **System Settings > Screen Saver**.

## Building from Source

### Prerequisites

- macOS 12.0 or later
- Xcode with Command Line Tools
- Swift 5.9 or later

### Quick Build

```bash
chmod +x build_all.sh
./build_all.sh
```

The app will be created at `BuatsaverApp/Buatsaver.app`.

### Manual Build

If you prefer to build step-by-step:

```bash
# 1. Build the screensaver template
xcodebuild -project Buatsaver.xcodeproj -scheme Buatsaver \
  -configuration Release CONFIGURATION_BUILD_DIR="./build/Release" build

# 2. Copy template to app resources
mkdir -p BuatsaverApp/Sources/BuatsaverApp/Resources
cp -r build/Release/Buatsaver.saver \
  BuatsaverApp/Sources/BuatsaverApp/Resources/Buatsaver.saver

# 3. Build and bundle the app
cd BuatsaverApp
swift build -c release
./bundle_app.sh
```

## Creating a Release

For maintainers:

```bash
# 1. Update version in VERSION file
echo "1.0.1" > VERSION

# 2. Build the app
./build_all.sh

# 3. Create DMG
cd dmg && ./create_dmg.sh && cd ..

# 4. Create GitHub release
gh release create v1.0.1 Buatsaver-1.0.1.dmg \
  --title "Buatsaver v1.0.1" \
  --notes "Release notes here"
```

## How It Works

Buatsaver consists of two components:

1. **Template Screensaver** (`Buatsaver/`): An Objective-C screensaver that plays videos using AVFoundation
2. **Builder App** (`BuatsaverApp/`): A SwiftUI app that packages your video into the template

## Technical Details

- The screensaver plays videos in a loop using `AVPlayer`
- Videos are scaled to fill the screen while maintaining aspect ratio
- Audio is muted by default
- The bundle identifier is automatically generated as `local.<hostname>.<user>.<name>`

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
