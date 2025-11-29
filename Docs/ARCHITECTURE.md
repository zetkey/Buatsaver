# Architecture and Project Structure

## Project Structure

Here's what you'll find when exploring the Buatsaver codebase:

```
Buatsaver/
├── BuatsaverApp/              # Main application
│   ├── Sources/
│   │   ├── BuatsaverApp.swift      # App entry point
│   │   ├── ContentView.swift       # Main UI
│   │   ├── SaverGenerator.swift    # Screensaver generation logic
│   │   ├── Models/                 # Data models
│   │   ├── Components/             # Reusable UI components
│   │   └── Utilities/              # Utility functions
│   ├── Resources/
│   └── Info.plist
├── BuatsaverScreensaver/      # Screensaver bundle
│   ├── Sources/
│   │   └── BuatsaverView.swift     # Screensaver implementation
│   └── Info.plist
├── Config/                    # Configuration files
├── Scripts/                   # Build and packaging scripts
│   ├── build.sh                    # Main build script
│   └── create_dmg.sh               # DMG creation script
├── Docs/                      # Documentation
├── build/                     # Build output directory
├── .github/                   # GitHub Actions workflows
├── backlogs/                  # Development backlogs
└── VERSION                    # Version file
```

## How Buatsaver is Built

The application follows a clean architectural pattern with distinct responsibilities:

- **Main Application**: Handles the user interface, file selection, and bundle creation
- **Screensaver Bundle**: The actual screensaver that plays videos, built on Apple's ScreenSaver framework
- **Component Layer**: Reusable UI elements that keep the code DRY
- **Security Layer**: Validation and protection against path traversal and other security issues
- **Performance Layer**: Caching and efficient resource management

## Key Components Explained

### Main Application (BuatsaverApp)

**BuatsaverApp.swift** serves as the entry point, setting up the SwiftUI window.

**ContentView.swift** handles all the main UI interactions:
- File selection (drag and drop or file picker)
- Thumbnail generation
- Screensaver configuration
- State management for the entire app

**SaverGenerator.swift** does the heavy lifting:
- Creates .saver bundle structures
- Manages file operations
- Handles the compilation process
- Enforces security validations

**Components/** contains reusable SwiftUI elements:
- **FileDropZone**: Handles video file drag and drop
- **ConfigurationSection**: Form for screensaver settings
- **ThumbnailCache**: Prevents regenerating thumbnails unnecessarily

**Models/** and **Utilities/** provide supporting code:
- **BuatsaverError**: Custom error types
- **ValidationUtility**: Bundle ID and other validations

### Screensaver Bundle (BuatsaverScreensaver)

**BuatsaverView.swift** implements the screensaver:
- Uses AVFoundation for video playback
- Manages the player lifecycle carefully to avoid memory leaks
- Implements seamless looping video playback
- Follows the ScreenSaver framework properly

## How Screensaver Generation Works

When a user creates a screensaver, here's what happens behind the scenes:

1. The user selects a video file through drag & drop or the file picker
2. Buatsaver automatically generates a thumbnail from the video
3. The user configures the screensaver name and settings
4. The application creates a new bundle containing:
   - The original video file
   - The thumbnail image
   - A compiled screensaver executable
   - The bundle's configuration (Info.plist)
5. The result is saved as a .saver file

## The Runtime Compilation Process

One of Buatsaver's unique features is runtime compilation. Here's how it works:

1. The app copies a Swift template file
2. Compiles it with a unique module name (based on the screensaver name)
3. Embeds the compiled executable in the screensaver bundle
4. This allows users to create multiple screensavers with different names without conflicts

## SaverGenerator: The Core Engine

**SaverGenerator** is responsible for creating screensaver bundles from video files. It's the engine that makes everything possible.

### The Main Function

The `createSaver` function takes several parameters:

- `targetURL`: Where to create the .saver bundle
- `sourceVideoURL`: The video file to embed
- `thumbnail`: Optional icon for the bundle
- `name`: Display name for the screensaver
- `identifier`: Bundle identifier (auto-validated)
- `progressCallback`: Optional progress updates

If something goes wrong, it throws one of these errors:
- `SaverGeneratorError.templateNotFound`: The Swift template is missing
- `SaverGeneratorError.invalidPath`: Security validation failed
- `SaverGeneratorError.compilationFailed`: Swift compilation failed

### What Happens Behind the Scenes

The function performs these steps:

1. **Module Name Creation**: Makes a safe module name from your screensaver name
2. **Bundle Structure Creation**: Sets up the Contents/MacOS/Resources directories
3. **Video Copying**: Copies your video to the Resources directory
4. **Thumbnail Processing**: Converts and saves your thumbnail
5. **Template Retrieval**: Gets the Swift template from the app bundle
6. **Compilation**: Compiles the screensaver executable with a unique name
7. **Info.plist Creation**: Generates the bundle's configuration file

### Security and Performance

SaverGenerator includes several safeguards:

- **Path security**: Prevents directory traversal attacks
- **Format validation**: Only allows safe video formats (mp4, mov, m4v)
- **Secure compilation**: Runs Swift compilation in a restricted environment
- **Bundle ID validation**: Ensures properly formatted bundle identifiers

Performance-wise, it's optimized for efficient file operations and minimal memory usage, with proper error handling to prevent resource leaks.

## Technical Implementation Details

Buatsaver leverages several modern technologies and techniques:

- **Video Playback**: Uses `AVPlayer` and `AVPlayerLayer` for smooth video playback
- **Aspect Ratio**: Videos fill the screen while maintaining aspect ratio using `.resizeAspectFill`
- **Audio Control**: Audio is muted by default (appropriate for screensavers)
- **Bundle ID Generation**: Automatically creates clean identifiers like `local.<hostname>.<user>.<name>`
- **Compilation**: Entirely Swift-based with runtime compilation
- **Memory Management**: Proper KVO observer removal and AVPlayer lifecycle management
- **UI Framework**: Modern SwiftUI with system-adaptive colors
- **File Handling**: Secure operations with path validation
- **Caching**: Thumbnail caching to avoid redundant work
- **Optimizations**: Compiler flags enabled for better performance