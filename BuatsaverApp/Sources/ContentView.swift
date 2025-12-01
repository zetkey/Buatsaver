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
    /// Handle for cancelling in-flight thumbnail generation work
    @State private var thumbnailTask: Task<Void, Never>?

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
        GeometryReader { proxy in
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    header

                    HStack(alignment: .top, spacing: 20) {
                        VStack(spacing: 16) {
                            SectionCard(title: "Source Video") {
                                FileDropZone(
                                    file: $videoURL,
                                    isDragging: $isDragging,
                                    onFileDrop: handleFileDrop
                                )

                                Text("Drag & drop an .mp4 or .mov file, or click to browse")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            SectionCard(title: "Thumbnail") {
                                ThumbnailPreview(
                                    isGeneratingThumbnail: isGeneratingThumbnail,
                                    thumbnailImage: thumbnailImage,
                                    onSelectThumbnail: selectThumbnail
                                )
                            }
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 16) {
                            SectionCard(title: "Configuration") {
                                ConfigurationSection(
                                    saverName: $saverName,
                                    saverIdentifier: $saverIdentifier,
                                    isBundleIdentifierValid: isBundleIdentifierValid
                                )
                                .onChange(of: saverName) { _ in updateBundleID() }
                            }

                            if !progressMessage.isEmpty {
                                SectionCard(title: "Progress") {
                                    Label {
                                        Text(progressMessage)
                                            .font(.system(size: 12, weight: .medium))
                                    } icon: {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }

                            if !statusMessage.isEmpty {
                                SectionCard(title: "Status") {
                                    Label(statusMessage, systemImage: statusIsError ? "exclamationmark.triangle" : "checkmark.circle.fill")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(statusIsError ? .red : .green)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    SectionCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Final step")
                                .font(.system(size: 14, weight: .semibold))

                            Text("We’ll package your video, thumbnail, and metadata into a signed screensaver bundle.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Button(action: generateSaver) {
                                Label {
                                    Text(isGenerating ? "Generating..." : "Generate Screensaver")
                                        .font(.system(size: 14, weight: .semibold))
                                } icon: {
                                    if isGenerating {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                    } else {
                                        Image(systemName: "sparkles")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .tint(.accentColor)
                            .disabled(generateButtonDisabled)
                            .keyboardShortcut(.return, modifiers: [.command])
                            .accessibilityLabel(isGenerating ? "Generating screensaver" : "Generate Screensaver")
                        }
                    }
                }
                .frame(maxWidth: min(proxy.size.width - 40, 860))
                .padding(24)
            }
        }
        .onAppear {
            updateBundleID()
        }
        .onDisappear {
            thumbnailTask?.cancel()
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
    @MainActor
    func generateThumbnail(from url: URL) {
        thumbnailTask?.cancel()

        if let cachedThumbnail = ThumbnailCache.shared.getThumbnail(for: url) {
            self.thumbnailImage = cachedThumbnail
            return
        }

        isGeneratingThumbnail = true

        thumbnailTask = Task(priority: .userInitiated) {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let duration = asset.duration
            let thumbnailSeconds = min(max(CMTimeGetSeconds(duration) * 0.2, 1.0), CMTimeGetSeconds(duration))
            let thumbnailTime = CMTime(seconds: thumbnailSeconds, preferredTimescale: duration.timescale)

            do {
                let cgImage = try imageGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
                let nsImage = NSImage(
                    cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

                guard !Task.isCancelled else { return }
                ThumbnailCache.shared.setThumbnail(nsImage, for: url)

                await MainActor.run {
                    self.thumbnailImage = nsImage
                    self.isGeneratingThumbnail = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    self.statusMessage = "Failed to generate thumbnail from video. Please ensure the video file is valid."
                    self.statusIsError = true
                    self.isGeneratingThumbnail = false
                }
            }
        }
    }

    @MainActor
    private func handleFileDrop(_ url: URL) {
        if let previousURL = videoURL {
            ThumbnailCache.shared.removeThumbnail(for: previousURL)
        }
        videoURL = url
        thumbnailImage = nil
        generateThumbnail(from: url)
    }

    private var generateButtonDisabled: Bool {
        videoURL == nil || saverName.isEmpty || isGenerating
    }

    private var generateButtonGradient: [Color] {
        if generateButtonDisabled {
            return [Color.gray.opacity(0.4), Color.gray.opacity(0.3)]
        }
        return [Color.accentColor, Color.purple]
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Buatsaver")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.white, .white.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                .accessibilityLabel("Buatsaver Application")

            Text("Craft polished video screensavers with preview thumbnails and custom bundle metadata.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
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

            // Capture main-actor state before hopping to a background queue
            let localVideoURL = videoURL
            let localThumbnail = thumbnailImage
            let localSaverName = saverName
            let localSaverIdentifier = saverIdentifier

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Update progress as each step completes
                    DispatchQueue.main.async {
                        progressMessage = "Creating bundle structure..."
                    }

                    try SaverGenerator.createSaver(
                        at: targetURL,
                        video: localVideoURL,
                        thumbnail: localThumbnail,
                        name: localSaverName,
                        identifier: localSaverIdentifier,
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
