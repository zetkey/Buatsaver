import SwiftUI

struct ThumbnailPreview: View {
    let isGeneratingThumbnail: Bool
    let thumbnailImage: NSImage?
    let onSelectThumbnail: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 120, height: 68)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                if isGeneratingThumbnail {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let image = thumbnailImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 68)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "photo")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("No thumbnail yet")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Preview thumbnail")
                    .font(.system(size: 13, weight: .semibold))
                Text("Use a generated frame or pick a custom still image.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Button(action: onSelectThumbnail) {
                    Label("Choose custom thumbnail", systemImage: "photo.on.rectangle")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.link)
                .disabled(isGeneratingThumbnail)
            }

            Spacer()
        }
    }
}
