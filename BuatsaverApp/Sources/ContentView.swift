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

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var thumbnailImage: NSImage?
    @State private var saverName: String = "MyScreensaver"
    @State private var saverIdentifier: String = ""
    @State private var isGenerating: Bool = false
    @State private var statusMessage: String = ""
    @State private var statusIsError: Bool = false
    @State private var isDragging: Bool = false

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

                    Text("Create video screensavers")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
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
                            videoURL = url
                            generateThumbnail(from: url)
                        }
                    )

                    // Thumbnail preview (compact)
                    if let img = thumbnailImage {
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
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField("Screensaver name", text: $saverName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)
                                .onChange(of: saverName) { _ in updateBundleID() }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bundle ID")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            TextField("Bundle identifier", text: $saverIdentifier)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .padding(10)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)
                        }
                    }
                    .padding(.horizontal, 20)

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

    func generateThumbnail(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVURLAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true

            do {
                let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                let nsImage = NSImage(
                    cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
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
        statusIsError = false

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "saver")!]
        savePanel.nameFieldStringValue = saverName

        savePanel.begin { response in
            guard response == .OK, let targetURL = savePanel.url else {
                isGenerating = false
                statusMessage = ""
                statusIsError = false
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try SaverGenerator.createSaver(
                        at: targetURL,
                        video: videoURL,
                        thumbnail: thumbnailImage,
                        name: saverName,
                        identifier: saverIdentifier
                    )

                    DispatchQueue.main.async {
                        isGenerating = false
                        statusMessage = "Screensaver created successfully"
                        statusIsError = false
                        NSWorkspace.shared.activateFileViewerSelecting([targetURL])
                    }
                } catch {
                    DispatchQueue.main.async {
                        isGenerating = false
                        statusMessage = "Error: \\(error.localizedDescription)"
                        statusIsError = true
                    }
                }
            }
        }
    }
}
