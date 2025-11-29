//
//  SaverGenerator.swift
//  Buatsaver
//
//  Handles the generation of .saver bundles from video files.
//

import AppKit
import Foundation

/// Errors that can occur during screensaver generation
enum SaverGeneratorError: LocalizedError {
    /// The screensaver template Swift file was not found in the app bundle
    case templateNotFound
    /// A file path failed security validation (likely path traversal attempt)
    case invalidPath
    /// Swift compilation failed with the provided error details
    case compilationFailed(String)

    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Screensaver template not found in app bundle"
        case .invalidPath:
            return "Invalid file path - security validation failed"
        case .compilationFailed(let details):
            return "Failed to compile screensaver: \(details)"
        }
    }
}

struct SaverGenerator {
    /// Creates a screensaver bundle from a video file.
    /// - Parameters:
    ///   - targetURL: The URL where the .saver bundle will be created
    ///   - sourceVideoURL: The URL of the source video file (must be .mp4 or .mov)
    ///   - thumbnail: Optional NSImage to use as the bundle icon
    ///   - name: The display name for the screensaver
    ///   - identifier: The bundle identifier (will be validated)
    ///   - progressCallback: Optional callback to report progress during generation
    /// - Throws: SaverGeneratorError if the operation fails
    /// - Note: This function performs runtime Swift compilation, which requires security validation
    static func createSaver(
        at targetURL: URL,
        video sourceVideoURL: URL,
        thumbnail: NSImage?,
        name: String,
        identifier: String,
        progressCallback: ((String) -> Void)? = nil
    ) throws {
        let fileManager = FileManager.default
        progressCallback?("Initializing...")

        // Create unique module name from the screensaver name
        let safeName = name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(
            separator: "")
        let moduleName = "Buatsaver_\(safeName)"

        // Remove existing if any
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }

        // Create bundle structure
        progressCallback?("Creating bundle structure...")
        let contentsURL = targetURL.appendingPathComponent("Contents")
        let macosURL = contentsURL.appendingPathComponent("MacOS")
        let resourcesURL = contentsURL.appendingPathComponent("Resources")

        try fileManager.createDirectory(at: macosURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

        // Copy video to Resources
        progressCallback?("Copying video file...")
        let ext = sourceVideoURL.pathExtension.lowercased()
        let targetVideoName = (ext == "mov") ? "video.mov" : "video.mp4"

        // Validate source video path to ensure it's a file (not a directory) and has safe extension
        guard sourceVideoURL.hasDirectoryPath == false else {
            throw SaverGeneratorError.invalidPath
        }

        guard ["mov", "mp4", "m4v"].contains(ext) else {
            throw SaverGeneratorError.invalidPath
        }

        let targetVideoURL = resourcesURL.appendingPathComponent(targetVideoName)

        // Ensure source file exists and is within safe bounds
        guard fileManager.fileExists(atPath: sourceVideoURL.path) else {
            throw SaverGeneratorError.invalidPath
        }

        try fileManager.copyItem(at: sourceVideoURL, to: targetVideoURL)

        // Save thumbnail
        progressCallback?("Saving thumbnail...")
        if let thumbnail = thumbnail {
            let thumbnailURL = resourcesURL.appendingPathComponent("thumbnail.png")
            if let tiffData = thumbnail.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffData),
                let pngData = bitmapImage.representation(using: .png, properties: [:])
            {
                try pngData.write(to: thumbnailURL)

                // Validate target file path to ensure it's a .saver bundle
                let targetPath = targetURL.path
                if targetPath.hasSuffix(".saver") && targetPath.contains("Buatsaver") {
                    NSWorkspace.shared.setIcon(thumbnail, forFile: targetPath, options: [])
                }
            }
        }

        // Get the Swift source file
        progressCallback?("Loading screensaver template...")
        guard let sourceURL = Bundle.main.url(forResource: "BuatsaverView", withExtension: "swift")
        else {
            throw SaverGeneratorError.templateNotFound
        }

        // Validate file path to prevent path traversal
        guard sourceURL.path.hasPrefix(Bundle.main.bundlePath) else {
            throw SaverGeneratorError.invalidPath
        }

        // Compile the screensaver with unique module name
        progressCallback?("Compiling screensaver...")
        let executableName = "BuatsaverScreensaver"
        let executableURL = macosURL.appendingPathComponent(executableName)

        // Validate output path to prevent path traversal
        let outputPath = executableURL.path
        let targetBundlePath = targetURL.path
        guard outputPath.hasPrefix(targetBundlePath) else {
            throw SaverGeneratorError.invalidPath
        }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/swiftc")
        task.arguments = [
            "-target", "x86_64-apple-macos12.0",
            "-emit-library",
            "-module-name", moduleName,
            "-framework", "ScreenSaver",
            "-framework", "AVFoundation",
            "-framework", "AVKit",
            "-framework", "Cocoa",
            "-Xlinker", "-install_name",
            "-Xlinker", "@executable_path/../MacOS/BuatsaverScreensaver",
            "-o", outputPath,
            sourceURL.path,
        ]

        // Capture stderr for better error messages
        let stderrPipe = Pipe()
        task.standardError = stderrPipe

        // Set secure environment for compilation
        task.environment = [
            "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
            "HOME": NSHomeDirectory()
        ]

        try task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else {
            // Get stderr output for detailed error message
            let errorData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown compilation error"

            throw SaverGeneratorError.compilationFailed(errorMessage)
        }

        // Create Info.plist
        let infoPlist: [String: Any] = [
            "CFBundleDevelopmentRegion": "en",
            "CFBundleExecutable": executableName,
            "CFBundleIdentifier": identifier,
            "CFBundleInfoDictionaryVersion": "6.0",
            "CFBundleName": name,
            "CFBundleDisplayName": name,
            "CFBundlePackageType": "BNDL",
            "CFBundleShortVersionString": "1.0",
            "CFBundleVersion": "1",
            "NSPrincipalClass": "\(moduleName).BuatsaverView",
            "NSHumanReadableCopyright": "Copyright © 2025. All rights reserved.",
        ]

        let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoPlist,
            format: .xml,
            options: 0
        )
        try plistData.write(to: infoPlistURL)
    }
}
