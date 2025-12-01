# Buatsaver

Buatsaver is a macOS utility that turns any `.mp4`, `.mov`, or `.m4v` video into a native screensaver bundle. The app is written entirely in Swift/SwiftUI and ships as a universal binary (arm64 + x86_64).

## Requirements

- macOS 12.0+
- Xcode Command Line Tools
- Swift 5.9+

## Build

```bash
make build          # Build app + screensaver (Release/universal)
make dmg            # Optional DMG packaging
make clean          # Remove build artifacts
```

Artifacts are written to `build/Release/` (`Buatsaver.app` and `BuatsaverScreensaver.saver`).

## Usage

1. Launch `Buatsaver.app`.
2. Drag a video into the left panel (or click to browse).
3. Optionally override the auto-generated thumbnail.
4. Name the saver; the bundle identifier is suggested automatically.
5. Click **Generate Screensaver** and choose the destination.
6. Double-click the resulting `.saver` to install it in **System Settings → Screen Saver**.

> **Gatekeeper note:** Buatsaver is currently unsigned. On first launch, right-click the app in Finder, choose **Open**, then confirm the security dialog. Alternatively you can remove the quarantine flag via `xattr -cr /Applications/Buatsaver.app`.

## Documentation

- [Architecture](Docs/ARCHITECTURE.md)
- [Build System Details](Docs/BUILD_SYSTEM.md)
- [Developer Guide](Docs/DEVELOPER_GUIDE.md)

## License

MIT License – see [LICENSE](LICENSE).