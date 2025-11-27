//
//  BuatsaverApp.swift
//  Buatsaver
//
//  A macOS application for creating custom video screensavers.
//

import SwiftUI
import AppKit
import AVFoundation

@main
struct BuatsaverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 500, minHeight: 500)
        }
    }
}

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var thumbnailImage: NSImage?
    @State private var saverName: String = "MyScreensaver"
    @State private var saverIdentifier: String = ""
    @State private var isGenerating: Bool = false
    @State private var statusMessage: String = ""
    @State private var statusIsError: Bool = false

    private var bundlePrefix: String {
        var hostName = ProcessInfo.processInfo.hostName
        if hostName.lowercased().hasSuffix(".local") {
            hostName = String(hostName.dropLast(6))
        }
        
        let userName = NSUserName()
        let safeHost = hostName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "").lowercased()
        let safeUser = userName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "").lowercased()
        return "local.\(safeHost).\(safeUser)"
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Buatsaver: Video to Screensaver")
                .font(.largeTitle)
                .padding(.top)

            // Video Selection
            VStack(alignment: .leading) {
                Text("1. Select Video File")
                    .font(.headline)
                HStack {
                    Text(videoURL?.lastPathComponent ?? "No video selected")
                        .foregroundColor(videoURL == nil ? .secondary : .primary)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    Button("Choose Video...") {
                        selectVideo()
                    }
                }
            }
            .padding(.horizontal)
            
            // Thumbnail Selection
            VStack(alignment: .leading) {
                Text("2. Thumbnail")
                    .font(.headline)
                
                HStack(alignment: .top) {
                    if let img = thumbnailImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 160, height: 90)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Rectangle()
                            .fill(Color(NSColor.controlBackgroundColor))
                            .frame(width: 160, height: 90)
                            .cornerRadius(6)
                            .overlay(
                                Text("No Thumbnail")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading) {
                        Button("Generate from Video") {
                            if let url = videoURL {
                                generateThumbnail(from: url)
                            }
                        }
                        .disabled(videoURL == nil)
                        
                        Button("Choose Image...") {
                            selectThumbnail()
                        }
                    }
                }
            }
            .padding(.horizontal)

            // Metadata
            VStack(alignment: .leading) {
                Text("3. Configuration")
                    .font(.headline)
                
                Form {
                    TextField("Screensaver Name", text: $saverName)
                        .onChange(of: saverName) { _ in updateBundleID() }
                    TextField("Bundle Identifier", text: $saverIdentifier)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
            }
            .padding(.horizontal)
            .onAppear {
                updateBundleID()
            }

            // Generate Action
            VStack {
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundColor(statusIsError ? .red : .green)
                        .font(.callout)
                }

                Button(action: generateSaver) {
                    Text(isGenerating ? "Generating..." : "Generate .saver")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(videoURL == nil || saverName.isEmpty || isGenerating)
            }
            .padding()
        }
        .padding()
    }

    /// Updates the bundle identifier based on the current screensaver name
    func updateBundleID() {
        let safeName = saverName.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "")
        saverIdentifier = "\(bundlePrefix).\(safeName)"
    }

    /// Presents a file picker for selecting a video file
    func selectVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            self.videoURL = url
            generateThumbnail(from: url)
        }
    }
    
    func selectThumbnail() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                self.thumbnailImage = image
            }
        }
    }
    
    func generateThumbnail(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                DispatchQueue.main.async {
                    self.thumbnailImage = nsImage
                }
            } catch {
                print("Failed to generate thumbnail: \(error)")
            }
        }
    }

    func generateSaver() {
        guard let videoURL = videoURL else { return }
        isGenerating = true
        statusMessage = "Preparing..."
        
        // 1. Ask where to save
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "saver")!]
        savePanel.nameFieldStringValue = saverName
        
        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else {
                isGenerating = false
                statusMessage = "Cancelled"
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try createSaver(at: targetURL, video: videoURL)
                    DispatchQueue.main.async {
                        isGenerating = false
                        statusMessage = "Success! Saved to \(targetURL.lastPathComponent)"
                        statusIsError = false
                        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                    }
                } catch {
                    DispatchQueue.main.async {
                        isGenerating = false
                        statusMessage = "Error: \(error.localizedDescription)"
                        statusIsError = true
                    }
                }
            }
        }
    }

    func createSaver(at targetURL: URL, video sourceVideoURL: URL) throws {
        let fileManager = FileManager.default
        
        // Locate template in Bundle
        // In Swift Package Manager executable, resources are accessed via Bundle.module
        guard let templateURL = Bundle.module.url(forResource: "Buatsaver", withExtension: "saver") else {
            throw NSError(domain: "Buatsaver", code: 1, userInfo: [NSLocalizedDescriptionKey: "Template saver not found in bundle."])
        }
        
        // Remove existing if any
        if fileManager.fileExists(atPath: targetURL.path) {
            try fileManager.removeItem(at: targetURL)
        }
        
        // Copy template to target
        try fileManager.copyItem(at: templateURL, to: targetURL)
        
        // Copy video
        let contentsURL = targetURL.appendingPathComponent("Contents")
        let resourcesURL = contentsURL.appendingPathComponent("Resources")
        
        // We need to ensure Resources exists (it should from the template)
        if !fileManager.fileExists(atPath: resourcesURL.path) {
            try fileManager.createDirectory(at: resourcesURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Determine extension (mp4 or mov)
        let ext = sourceVideoURL.pathExtension.lowercased()
        let targetVideoName = (ext == "mov") ? "video.mov" : "video.mp4"
        let targetVideoURL = resourcesURL.appendingPathComponent(targetVideoName)
        
        // Remove placeholder video if exists
        let placeholderMP4 = resourcesURL.appendingPathComponent("video.mp4")
        let placeholderMOV = resourcesURL.appendingPathComponent("video.mov")
        if fileManager.fileExists(atPath: placeholderMP4.path) { try fileManager.removeItem(at: placeholderMP4) }
        if fileManager.fileExists(atPath: placeholderMOV.path) { try fileManager.removeItem(at: placeholderMOV) }
        
        // Copy new video
        try fileManager.copyItem(at: sourceVideoURL, to: targetVideoURL)
        
        // Save Thumbnail
        if let thumbnail = thumbnailImage {
            let thumbnailURL = resourcesURL.appendingPathComponent("thumbnail.png")
            if let tiffData = thumbnail.tiffRepresentation,
               let bitmapImage = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapImage.representation(using: .png, properties: [:]) {
                try pngData.write(to: thumbnailURL)
                
                // Set file icon
                NSWorkspace.shared.setIcon(thumbnail, forFile: targetURL.path, options: [])
            }
        }
        
        // Update Info.plist
        let infoPlistURL = contentsURL.appendingPathComponent("Info.plist")
        if let plistData = try? Data(contentsOf: infoPlistURL) {
            var plistFormat = PropertyListSerialization.PropertyListFormat.xml
            if var plist = try PropertyListSerialization.propertyList(from: plistData, options: .mutableContainersAndLeaves, format: &plistFormat) as? [String: Any] {
                
                plist["CFBundleName"] = saverName
                plist["CFBundleDisplayName"] = saverName
                plist["CFBundleIdentifier"] = saverIdentifier
                plist["CFBundleExecutable"] = "Buatsaver" // The binary name in the template is Buatsaver (from the target name)
                
                let newData = try PropertyListSerialization.data(fromPropertyList: plist, format: plistFormat, options: 0)
                try newData.write(to: infoPlistURL)
            }
        }
    }
}
