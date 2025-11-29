//
//  FileDropZone.swift
//  Buatsaver
//
//  A minimalist drag-and-drop zone for video files.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileDropZone: View {
    @Binding var file: URL?
    @Binding var isDragging: Bool
    let onFileDrop: (URL) -> Void

    var body: some View {
        ZStack {
            // Clean border
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isDragging ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(
                        lineWidth: isDragging ? 2 : 1, dash: isDragging ? [] : [6, 3])
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isDragging
                                ? Color.accentColor.opacity(0.05)
                                : Color(nsColor: .controlBackgroundColor))
                )
                .animation(.easeInOut(duration: 0.2), value: isDragging)

            VStack(spacing: 16) {
                if let videoURL = file {
                    // Video selected state
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.green)

                        Text(videoURL.lastPathComponent)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .truncationMode(.middle)
                            .padding(.horizontal, 20)

                        Button("Choose Different Video") {
                            selectVideo()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                    }
                    .padding()
                } else {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: isDragging ? "arrow.down.circle.fill" : "film")
                            .font(.system(size: 32))
                            .foregroundColor(isDragging ? .accentColor : .secondary)
                            .animation(.easeInOut(duration: 0.2), value: isDragging)

                        Text(isDragging ? "Drop video here" : "Drag video here")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        Text("or")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Button("Choose Video File") {
                            selectVideo()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)

                        Text("Supports .mp4 and .mov")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
        .frame(height: 180)
        .onDrop(of: [.fileURL], isTargeted: $isDragging) { providers in
            guard let provider = providers.first else { return false }

            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
                (urlData, error) in
                if let urlData = urlData as? Data,
                    let path = String(data: urlData, encoding: .utf8),
                    let url = URL(string: path)
                {
                    DispatchQueue.main.async {
                        onFileDrop(url)
                    }
                }
            }
            return true
        }
    }

    private func selectVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            onFileDrop(url)
        }
    }
}
