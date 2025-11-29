//
//  SaverGenerator.swift
//  Buatsaver
//
//  Handles the generation of .saver bundles from video files.
//

import AppKit
import Foundation

enum SaverGeneratorError: LocalizedError {
    case templateNotFound
    case invalidPath

    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Screensaver template not found in app bundle"
        case .invalidPath:
            return "Invalid file path"
        }
    }
}

struct SaverGenerator {
    static func createSaver(
        at targetURL: URL,
        video sourceVideoURL: URL,
        thumbnail: NSImage?,
        name: String,
        identifier: String
    ) throws {
        let fileManager = FileManager.default

        // Create unique module name from the screensaver name
        let safeName = name.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(
            separator: "")
        let moduleName = "Buatsaver_\(safeName)"

        // Remove existing if any
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }

        // Create bundle structure
        let contentsURL = targetURL.appendingPathComponent("Contents")
        let macosURL = contentsURL.appendingPathComponent("MacOS")
        let resourcesURL = contentsURL.appendingPathComponent("Resources")

        try fileManager.createDirectory(at: macosURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true)

        // Copy video to Resources
        let ext = sourceVideoURL.pathExtension.lowercased()
        let targetVideoName = (ext == "mov") ? "video.mov" : "video.mp4"
        let targetVideoURL = resourcesURL.appendingPathComponent(targetVideoName)
        try fileManager.copyItem(at: sourceVideoURL, to: targetVideoURL)

        // Save thumbnail
        if let thumbnail = thumbnail {
            let thumbnailURL = resourcesURL.appendingPathComponent("thumbnail.png")
            if let tiffData = thumbnail.tiffRepresentation,
                let bitmapImage = NSBitmapImageRep(data: tiffData),
                let pngData = bitmapImage.representation(using: .png, properties: [:])
            {
                try pngData.write(to: thumbnailURL)
                NSWorkspace.shared.setIcon(thumbnail, forFile: targetURL.path, options: [])
            }
        }

        // Get the Swift source file
        guard let sourceURL = Bundle.main.url(forResource: "BuatsaverView", withExtension: "swift")
        else {
            throw SaverGeneratorError.templateNotFound
        }

        // Compile the screensaver with unique module name
        let executableName = "BuatsaverScreensaver"
        let executableURL = macosURL.appendingPathComponent(executableName)

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
            "-o", executableURL.path,
            sourceURL.path,
        ]

        try task.run()
        task.waitUntilExit()

        guard task.terminationStatus == 0 else {
            throw NSError(
                domain: "SaverGenerator", code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to compile screensaver"
                ])
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
