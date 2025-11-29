//
//  ContentView.swift
//  Buatsaver
//
//  Sleek, minimalist interface for creating video screensavers.
//

import AVFoundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Main application view for Buatsaver
/// Provides the user interface for creating video screensavers
struct ContentView: View {
    /// The URL of the currently selected video file
    @State private var videoURL: URL?
    /// The thumbnail image for the selected video
    @State private var thumbnailImage: NSImage?
    /// The user-specified name for the screensaver
    @State private var saverName: String = "MyScreensaver"
    /// The bundle identifier for the screensaver
    @State private var saverIdentifier: String = ""
    /// Whether the screensaver generation is currently in progress
    @State private var isGenerating: Bool = false
    /// Status message to display to the user
    @State private var statusMessage: String = ""
    /// Whether the current status message is an error
    @State private var statusIsError: Bool = false
    /// Whether a file is currently being dragged over the drop zone
    @State private var isDragging: Bool = false
    /// Whether thumbnail generation is currently in progress
    @State private var isGeneratingThumbnail: Bool = false
    /// Progress message during screensaver generation
    @State private var progressMessage: String = ""

    private var bundlePrefix: String {
        var hostName = ProcessInfo.processInfo.hostName
        if hostName.lowercased().hasSuffix(".local") {
            hostName = String(hostName.dropLast(6))
        }

        let userName = NSUserName()
        let safeHost = hostName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(
            separator: ""
        ).lowercased()
        let safeUser = userName.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(
            separator: ""
        ).lowercased()
        return "local.\(safeHost).\(safeUser)"
    }

    private var isBundleIdentifierValid: Bool {
        return ValidationUtility.isValidBundleIdentifier(saverIdentifier)
    }

    var body: some View {
        ZStack {
            // Clean background
            Color(nsColor: NSColor.windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Minimal header
                VStack(spacing: 8) {
                    Text("Buatsaver")
                        .font(.system(size: 28, weight: .light, design: .default))
                        .foregroundColor(.primary)
                        .accessibilityLabel("Buatsaver Application")

                    Text("Create video screensavers")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Create custom video screensavers from your video files")
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Main content
                VStack(spacing: 24) {
                    // Video selection
                    FileDropZone(
                        file: $videoURL,
                        isDragging: $isDragging,
                        onFileDrop: { url in
                            // Clear previous thumbnail from cache if we had one
                            if let previousURL = videoURL {
                                ThumbnailCache.shared.removeThumbnail(for: previousURL)
                            }
                            videoURL = url
                            thumbnailImage = nil  // Clear previous thumbnail
                            generateThumbnail(from: url)
                        }
                    )

                    // Thumbnail preview (compact)
                    if isGeneratingThumbnail {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 80, height: 45)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Generating thumbnail...")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    } else if let img = thumbnailImage {
                        HStack(spacing: 12) {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 45)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Thumbnail")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)

                                Button("Change") {
                                    selectThumbnail()
                                }
                                .buttonStyle(.plain)
                                .font(.system(size: 11))
                                .foregroundColor(.accentColor)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                    }

                    Divider()
                        .padding(.horizontal, 20)

                    // Configuration fields
                    ConfigurationSection(
                        saverName: $saverName,
                        saverIdentifier: $saverIdentifier,
                        isBundleIdentifierValid: isBundleIdentifierValid
                    )
                    .onChange(of: saverName) { _ in updateBundleID() }
                    .padding(.horizontal, 20)

                    // Progress message
                    if !progressMessage.isEmpty {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 12, height: 12)
                            Text(progressMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Status message
                    if !statusMessage.isEmpty {
                        HStack(spacing: 8) {
                            Image(
                                systemName: statusIsError
                                    ? "exclamationmark.circle" : "checkmark.circle"
                            )
                            .font(.system(size: 12))
                            Text(statusMessage)
                                .font(.system(size: 12))
                        }
                        .foregroundColor(statusIsError ? .red : .green)
                        .padding(.horizontal, 20)
                    }

                    // Generate button
                    Button(action: generateSaver) {
                        HStack(spacing: 8) {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .frame(width: 14, height: 14)
                            }
                            Text(isGenerating ? "Generating..." : "Generate Screensaver")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            videoURL == nil || saverName.isEmpty || isGenerating
                                ? Color.secondary.opacity(0.3) : Color.accentColor
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(videoURL == nil || saverName.isEmpty || isGenerating)
                    .keyboardShortcut(.return, modifiers: [.command])
                    .accessibilityLabel(isGenerating ? "Generating screensaver" : "Generate Screensaver")
                    .accessibilityHint("Create a new screensaver from the selected video")
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: 500)
        }
        .onAppear {
            updateBundleID()
        }
    }

    // MARK: - Helper Functions

    func updateBundleID() {
        let safeName = saverName.lowercased().components(
            separatedBy: CharacterSet.alphanumerics.inverted
        ).joined(separator: "")
        saverIdentifier = "\(bundlePrefix).\(safeName)"
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

    /// Generates a thumbnail image from the specified video URL
    /// Uses caching to avoid regenerating thumbnails for the same video
    /// - Parameter url: The URL of the video file to generate a thumbnail from
    func generateThumbnail(from url: URL) {
        // Check if thumbnail is already cached
        if let cachedThumbnail = ThumbnailCache.shared.getThumbnail(for: url) {
            self.thumbnailImage = cachedThumbnail
            return
        }

        isGeneratingThumbnail = true
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            // Set time to 20% into the video for a better thumbnail, or 1 second if video is short
            let duration = asset.duration
            let thumbnailSeconds = min(max(CMTimeGetSeconds(duration) * 0.2, 1.0), CMTimeGetSeconds(duration))
            let thumbnailTime = CMTime(seconds: thumbnailSeconds, preferredTimescale: duration.timescale)

            do {
                let cgImage = try imageGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
                let nsImage = NSImage(
                    cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

                // Cache the thumbnail
                ThumbnailCache.shared.setThumbnail(nsImage, for: url)

                DispatchQueue.main.async {
                    self.thumbnailImage = nsImage
                    self.isGeneratingThumbnail = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.statusMessage = "Failed to generate thumbnail from video. Please ensure the video file is valid."
                    self.statusIsError = true
                    self.isGeneratingThumbnail = false
                }
            }
        }
    }

    func generateSaver() {
        guard let videoURL = videoURL else { return }
        isGenerating = true
        progressMessage = "Initializing..."
        statusMessage = "Preparing to generate screensaver..."
        statusIsError = false

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "saver")!]
        savePanel.nameFieldStringValue = saverName

        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else {
                DispatchQueue.main.async {
                    isGenerating = false
                    statusMessage = ""
                    progressMessage = ""
                    statusIsError = false
                }
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Update progress as each step completes
                    DispatchQueue.main.async {
                        progressMessage = "Creating bundle structure..."
                    }

                    try SaverGenerator.createSaver(
                        at: targetURL,
                        video: videoURL,
                        thumbnail: thumbnailImage,
                        name: saverName,
                        identifier: saverIdentifier,
                        progressCallback: { message in
                            DispatchQueue.main.async {
                                self.progressMessage = message
                            }
                        }
                    )

                    DispatchQueue.main.async {
                        isGenerating = false
                        progressMessage = ""
                        statusMessage = "Screensaver created successfully"
                        statusIsError = false
                        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                    }
                } catch {
                    DispatchQueue.main.async {
                        isGenerating = false
                        progressMessage = ""
                        statusMessage = "Error: \(error.localizedDescription)"
                        statusIsError = true
                    }
                }
            }
        }
    }
}
