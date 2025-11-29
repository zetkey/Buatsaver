# Changelog

All notable changes to Buatsaver will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-11-29

### Added
- **Universal Binary Support**: App now runs natively on both Apple Silicon (M1/M2/M3/M4) and Intel Macs
- **Automatic Architecture Detection**: Generated screensavers are automatically optimized for the user's Mac architecture
- **AVPlayerLooper Integration**: Seamless video looping without gaps or black screens
- **Performance Optimizations**: 10-second video buffer for smooth playback
- **Build System**: Universal binary build process using lipo

### Changed
- **Video Playback Engine**: Migrated from `AVPlayer` to `AVQueuePlayer` with `AVPlayerLooper`
- **Player Configuration**: Enabled `automaticallyWaitsToMinimizeStalling` for better buffering
- **Player Layer**: Added black background to prevent visual flashes
- **Asset Loading**: Preload video metadata keys for faster playback initialization
- **Build Targets**: Changed from x86_64-only to universal binaries (arm64 + x86_64)

### Fixed
- **Stuttering on Apple Silicon**: Eliminated Rosetta 2 translation overhead by compiling native arm64 binaries
- **Black Screens Between Loops**: Fixed with proper AVPlayerLooper configuration and explicit time ranges
- **Periodic Stuttering**: Resolved by fixing player configuration and removing unnecessary display link code

### Removed
- **CVDisplayLink**: Removed display link synchronization code that was causing stuttering
- **Manual Looping**: Replaced manual seek-based looping with AVPlayerLooper

### Performance
- CPU usage reduced to < 5% on modern Macs (previously 10-15% on Apple Silicon via Rosetta 2)
- Smooth, stutter-free playback on all supported architectures
- Native performance on both Apple Silicon and Intel Macs

## [2.1.1] - Previous Release

### Features
- Video screensaver generation from .mp4 and .mov files
- Automatic thumbnail generation
- Custom bundle identifiers
- SwiftUI-based interface
- Runtime Swift compilation

---

## Version History

- **3.0.0** - Universal Binary Support & Performance Improvements
- **2.1.1** - Previous stable release
