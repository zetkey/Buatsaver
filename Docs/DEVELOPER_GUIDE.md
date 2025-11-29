# Developer Guide for Buatsaver

This guide helps you get started with developing Buatsaver and understand how everything works together.

## Setting Up Your Development Environment

### What You Need
- macOS 12.0 or later
- Xcode Command Line Tools
- Swift 5.9 or later

### Getting Started
1. **Get the code:**
   ```bash
   git clone <repository-url>
   cd Buatsaver
   ```

2. **Check your Swift version:**
   ```bash
   swift --version
   ```

3. **Build the project:**
   ```bash
   make build
   # or if you prefer the script directly:
   ./Scripts/build.sh
   ```

## Understanding the Codebase

### Technologies We Use
- **SwiftUI**: For the main application UI
- **ScreenSaver Framework**: For the screensaver functionality
- **AVFoundation**: For video playback and thumbnail generation
- **Foundation**: For core functionality and file operations

### Key Files and What They Do

**SaverGenerator.swift** is the heart of the application. It:
- Creates the proper .saver bundle structure
- Copies your video and thumbnail files
- Compiles Swift code at runtime (that's the cool part!)
- Generates the Info.plist file

**ContentView.swift** handles video thumbnail generation and uses **ThumbnailCache.swift** to avoid doing extra work when you're switching between videos.

**BuatsaverView.swift** (in the screensaver part) manages video playback and makes sure to clean up memory properly so there are no leaks.

## Common Development Tasks

### Adding a New UI Component
1. Create your component in `BuatsaverApp/Sources/Components/`
2. Add it to the build script in `Scripts/build.sh`
3. Use it in your view

### Changing Screensaver Behavior
1. Edit `BuatsaverScreensaver/Sources/BuatsaverView.swift`
2. Test by generating a new screensaver after your changes
3. Remember: screensaver changes need a full rebuild

### Adding Validation
1. Add your validation to `ValidationUtility.swift`
2. Update the UI to show the validation results
3. Make sure error messages are user-friendly

### Optimizing App Bundle Size
1. For icon optimization, place a high-resolution PNG in `BuatsaverApp/Resources/`
2. Generate all required sizes using sips:
   ```bash
   sips -z 16 16 buatsaver.png --out icon_16x16.png
   sips -z 32 32 buatsaver.png --out icon_16x16@2x.png
   # ... continue for all required sizes
   ```
3. Apply ImageMagick optimization:
   ```bash
   magick input.png -quality 85 -define png:compression-level=9 output.png
   ```
4. Create the ICNS file:
   ```bash
   iconutil -c icns iconset_folder
   ```

### Adding Build Optimizations
1. Update build scripts with flags like `-O`
2. Remove unnecessary files from bundle resources
3. Always test the build process after changes
4. Verify all functionality still works

### Working with SaverGenerator
1. Core logic is in `SaverGenerator.swift`
2. It does runtime Swift compilation for each screensaver
3. Security validations are critical when modifying
4. Always test with different video formats and file paths

## Coding Guidelines

### Swift Style
- Follow the Swift API Design Guidelines
- Use modern Swift features appropriately
- Prefer structs over classes when you can
- Use private by default for access control
- Choose descriptive names for variables and functions

### SwiftUI Best Practices
- Use `@State`, `@Binding`, and `@ObservedObject` appropriately
- Break big views into smaller, focused components
- Add accessibility modifiers to interactive elements
- Handle loading and error states properly

### Error Handling
- Use proper error types in Swift
- Give users meaningful error messages
- Log technical details for debugging
- Fail gracefully when things go wrong

## Testing Your Changes

### Basic Testing Workflow
1. Build the application: `make build`
2. Test video import to make sure it still works
3. Test thumbnail generation
4. Test creating a screensaver
5. Verify your generated screensaver works in System Settings

### Build Verification
Always run this after changes:
```bash
make build
```

## Contributing to Buatsaver

### Pull Request Workflow
1. Fork the repository
2. Create a feature branch for your work
3. Make your changes
4. Make sure the build still works
5. Update documentation if needed
6. Submit your pull request with a clear description

### Code Review Checklist
- [ ] Build process works without errors
- [ ] New features have good UI/UX
- [ ] Security measures are still in place
- [ ] Performance hasn't regressed
- [ ] Error handling is thorough
- [ ] Code follows our style
- [ ] Documentation is up to date

## Troubleshooting Common Issues

### Build Problems
- Make sure Xcode Command Line Tools are installed
- Verify the Swift compiler is accessible
- Check that file paths don't have unusual characters

### Screensaver Debugging
- Look in Console.app for screensaver logs
- Check for NSLog statements in BuatsaverView.swift
- Verify the bundle structure manually if needed

### Thumbnail Issues
- Confirm video files are valid and accessible
- Check that AVFoundation supports the format
- Ensure your system has enough memory for large videos

## Releasing New Versions

When you're maintaining Buatsaver and ready to publish a new version:

1. **Update the version number**
   ```bash
   echo "2.0.1" > VERSION
   ```

2. **Build and test the application**
   ```bash
   make build
   ```

3. **Create the distribution package**
   ```bash
   make dmg
   ```

4. **Publish on GitHub**
   ```bash
   gh release create v2.0.1 Buatsaver-2.0.1.dmg \
     --title "Buatsaver v2.0.1" \
     --notes "Release notes here"
   ```

That's the complete process for creating and publishing a new release.