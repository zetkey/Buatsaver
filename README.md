# Buatsaver

A modern macOS application that converts video files into native screensavers. Built with pure Swift and SwiftUI.

## Features

- **Universal Binary**: Native support for both Apple Silicon (M1/M2/M3) and Intel Macs
- **Optimized Performance**: Smooth, stutter-free video playback with AVPlayerLooper
- **Modern SwiftUI Interface**: Beautiful, intuitive drag-and-drop interface
- **Video Support**: Works with `.mp4` and `.mov` files
- **Auto-Thumbnail**: Automatically generates thumbnails from your videos
- **Custom Icons**: Sets the generated screensaver's icon to the thumbnail
- **Smart Bundle IDs**: Automatically generates clean bundle identifiers
- **Architecture Detection**: Automatically generates screensavers optimized for your Mac's architecture

## System Requirements

- macOS 12.0 or later
- Works on both Apple Silicon (M1/M2/M3) and Intel Macs

## Building from Source

### Prerequisites

- macOS 12.0 or later
- Xcode Command Line Tools
- Swift 5.9 or later

### Quick Build

```bash
make build
```

The app will be created at `build/Release/Buatsaver.app`.

### Using Make

```bash
make build          # Build the application (universal binary)
make dmg            # Build and create DMG
make clean          # Clean build artifacts
```

### Build Output

The build process creates universal binaries (arm64 + x86_64):
- `build/Release/Buatsaver.app` - Main application bundle
- `build/Release/BuatsaverScreensaver.saver` - Pre-built screensaver bundle

### Architecture Support

The build system automatically creates universal binaries that run natively on both:
- **Apple Silicon** (M1, M2, M3, M4) - arm64
- **Intel Macs** - x86_64

When you generate a screensaver, the app automatically detects your Mac's architecture and creates an optimized screensaver for maximum performance.

## Installation (For Built App)

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
3. (Optional) Customize the thumbnail by clicking **Change**
4. Enter a name for your screensaver
5. Click **Generate Screensaver**
6. Double-click the generated `.saver` file to install

The screensaver will appear in **System Settings > Screen Saver**.

## Performance

Version 3.0.0 includes significant performance improvements:

- **Native Apple Silicon support** - No Rosetta 2 translation overhead
- **Optimized video playback** - Using AVPlayerLooper for seamless looping
- **Smooth playback** - 10-second buffer for stutter-free performance
- **Low CPU usage** - Typically < 5% on modern Macs

## Technical Details

For developers interested in the technical implementation:

- **Video Playback**: AVQueuePlayer with AVPlayerLooper for seamless looping
- **Architecture Detection**: Compile-time detection for optimal screensaver generation
- **Build System**: Universal binaries using lipo to combine arm64 and x86_64
- **Frameworks**: ScreenSaver, AVFoundation, SwiftUI, AppKit

See [Docs/](Docs/) for detailed technical documentation.

## License

MIT License - see [LICENSE](LICENSE) file for details