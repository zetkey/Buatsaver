# Buatsaver

A modern macOS application that converts video files into native screensavers. Built with pure Swift and SwiftUI.

## Features

- **Modern SwiftUI Interface**: Beautiful, intuitive drag-and-drop interface
- **Video Support**: Works with `.mp4` and `.mov` files
- **Auto-Thumbnail**: Automatically generates thumbnails from your videos
- **Custom Icons**: Sets the generated screensaver's icon to the thumbnail
- **Smart Bundle IDs**: Automatically generates clean bundle identifiers
- **Native Performance**: Built entirely in Swift for optimal performance

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
2. **Drag and drop** your video file or click **Choose Video File**
3. (Optional) Customize the thumbnail by clicking **Choose Image** or **Generate from Video**
4. Enter a name for your screensaver
5. Click **Generate Screensaver**
6. Double-click the generated `.saver` file to install

The screensaver will appear in **System Settings > Screen Saver**.

## Building from Source

### Prerequisites

- macOS 12.0 or later
- Xcode Command Line Tools
- Swift 5.9 or later

### Quick Build

```bash
chmod +x Scripts/build.sh
./Scripts/build.sh
```

The app will be created at `build/Release/Buatsaver.app`.

### Manual Build Steps

The build script compiles both the screensaver bundle and the main app:

```bash
# Build screensaver
swiftc -target x86_64-apple-macos12.0 \
    -framework ScreenSaver -framework AVFoundation \
    -emit-executable \
    -o build/Release/BuatsaverScreensaver.saver/Contents/MacOS/BuatsaverScreensaver \
    BuatsaverScreensaver/Sources/BuatsaverView.swift

# Build app
swiftc -target x86_64-apple-macos12.0 \
    -framework SwiftUI -framework AppKit -framework AVFoundation \
    -emit-executable \
    -o build/Release/Buatsaver.app/Contents/MacOS/BuatsaverApp \
    BuatsaverApp/Sources/*.swift BuatsaverApp/Sources/Components/*.swift
```

## Creating a Release

For maintainers:

```bash
# 1. Update version in VERSION file
echo "1.0.1" > VERSION

# 2. Build the app
./Scripts/build.sh

# 3. Create DMG
./Scripts/create_dmg.sh

# 4. Create GitHub release
gh release create v1.0.1 Buatsaver-1.0.1.dmg \
  --title "Buatsaver v1.0.1" \
  --notes "Release notes here"
```

## Project Structure

```
Buatsaver/
├── BuatsaverApp/              # Main SwiftUI application
│   ├── Sources/
│   │   ├── BuatsaverApp.swift      # App entry point
│   │   ├── ContentView.swift       # Main UI
│   │   ├── SaverGenerator.swift    # Screensaver generation logic
│   │   └── Components/             # Reusable UI components
│   ├── Resources/
│   └── Info.plist
├── BuatsaverScreensaver/      # Screensaver bundle
│   ├── Sources/
│   │   └── BuatsaverView.swift     # Swift screensaver implementation
│   └── Info.plist
├── Scripts/
│   ├── build.sh                    # Unified build script
│   └── create_dmg.sh               # DMG creation script
├── build/                          # Build output
├── VERSION                         # Version file
└── README.md
```

## How It Works

Buatsaver consists of two components:

1. **Screensaver Bundle** (`BuatsaverScreensaver/`): A Swift-based screensaver that plays videos using AVFoundation
2. **Builder App** (`BuatsaverApp/`): A SwiftUI app that packages your video into the screensaver template

The app embeds the screensaver template and customizes it with your video, thumbnail, and metadata.

## Technical Details

- The screensaver plays videos in a loop using `AVPlayer`
- Videos are scaled to fill the screen while maintaining aspect ratio
- Audio is muted by default
- The bundle identifier is automatically generated as `local.<hostname>.<user>.<name>`
- Built entirely in Swift - no Objective-C dependencies
- Modern SwiftUI interface with gradient backgrounds and smooth animations

## License

MIT License - see [LICENSE](LICENSE) file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
