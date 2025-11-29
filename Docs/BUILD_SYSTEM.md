# Build System Documentation

## Overview
Buatsaver uses a shell script-based build system that compiles both the main application and the screensaver bundle using Swift compiler directly.

## Building the Project

### What You Need
Before building Buatsaver, make sure you have:
- macOS 12.0 or later
- Xcode Command Line Tools installed
- Swift 5.9 or later
- ImageMagick for icon optimization (install with `brew install imagemagick`)

### The Build Scripts

The project uses two main scripts:

**`Scripts/build.sh`** handles the core build process:
1. Compiles the screensaver bundle as a dynamic library
2. Compiles the main application with optimizations (-O flag)
3. Sets up the proper bundle structure
4. Performs ad-hoc code signing

**`Scripts/create_dmg.sh`** packages everything into a user-friendly DMG:
- Professional layout for easy installation
- Symlink to Applications folder
- README with installation instructions
- Custom background (if you have one)

### Building the Project

You can build using the scripts directly:

```bash
chmod +x Scripts/build.sh
./Scripts/build.sh
```

Or use the Makefile for convenience:

```bash
make build          # Compile the application
make dmg            # Build and create a DMG
make clean          # Remove build artifacts
make test           # Run tests (placeholder for future use)
```

### Build Output

When the build completes, you'll find:
- `build/Release/Buatsaver.app` - The main application bundle
- `build/Release/BuatsaverScreensaver.saver` - The screensaver bundle

## Continuous Integration

We use GitHub Actions for automated building. The workflow in `.github/workflows/build.yml`:
- Builds the project on every push to main
- Runs on pull requests to catch issues early
- Creates DMG files only when pushing to main
- Archives build artifacts for 30 days
- Verifies everything builds correctly

## Making Your Build More Efficient

### Size Optimizations

The build system includes several optimizations to keep the app size reasonable:

- **Compiler flags**: Uses `-O` for optimized release builds
- **Resource cleanup**: Unnecessary files are removed from the final bundle
- **Icon optimization**: The app icon is carefully optimized to ~455KB instead of the original 1.9MB+

### Optimizing the App Icon

The app icon makes a big difference in bundle size. Here's how we optimize it:

```bash
# Create an iconset directory
mkdir buatsaver_icon.iconset

# Generate all the sizes macOS needs
sips -z 16 16 buatsaver.png --out icon_16x16.png
sips -z 32 32 buatsaver.png --out icon_16x16@2x.png
sips -z 32 32 buatsaver.png --out icon_32x32.png
sips -z 64 64 buatsaver.png --out icon_32x32@2x.png
sips -z 128 128 buatsaver.png --out icon_128x128.png
sips -z 256 256 buatsaver.png --out icon_128x128@2x.png
sips -z 256 256 buatsaver.png --out icon_256x256.png
sips -z 512 512 buatsaver.png --out icon_256x256@2x.png
sips -z 512 512 buatsaver.png --out icon_512x512.png
sips -z 512 512 buatsaver.png --out icon_512x512@2x.png

# Apply ImageMagick compression to reduce file sizes
for file in *.png; do
  magick "$file" -quality 85 -define png:compression-level=9 "$file"
done

# Create the final ICNS file
iconutil -c icns buatsaver_icon.iconset
```

This process reduces the icon from 1.9MB to about 455KB while maintaining good visual quality.

## Security in the Build Process

The build process includes several security measures:

- **Runtime compilation safety**: Swift compilation is carefully contained and validated
- **Path protection**: All file operations include traversal protection
- **Environment restrictions**: Compilation runs with limited environment variables and a restricted PATH
- **Format validation**: Only approved video formats are allowed