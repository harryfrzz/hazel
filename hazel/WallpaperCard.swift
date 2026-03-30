import SwiftUI
import AppKit

struct WallpaperCard: View {
    let item: WallpaperItem
    let isSelected: Bool
    let onTap: () -> Void
    let onRemove: () -> Void
    let onToggleLoop: () -> Void

    @State private var thumbnailImage: NSImage?

    private let cardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 140
    private let thumbnailWidth: CGFloat = 140
    private let thumbnailHeight: CGFloat = 79

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image = thumbnailImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                        .overlay(
                            Image(systemName: "video.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }

                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .frame(width: thumbnailWidth, height: thumbnailHeight)
                }
            }
            .frame(width: thumbnailWidth, height: thumbnailHeight)
            .cornerRadius(4)
            .onTapGesture(perform: onTap)

            Text(item.title)
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: cardWidth - 16)
        }
        .frame(width: cardWidth, height: cardHeight)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.1))
        )
        .contextMenu {
            Button(item.isLooping ? "Disable Loop" : "Enable Loop", action: onToggleLoop)
            Divider()
            Button("Remove", role: .destructive, action: onRemove)
        }
        .onAppear(perform: loadThumbnail)
    }

    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async {
            let fileManager = FileManager.default
            if let thumbnailPath = item.thumbnailPath,
               fileManager.fileExists(atPath: thumbnailPath),
               let image = NSImage(contentsOfFile: thumbnailPath) {
                DispatchQueue.main.async {
                    self.thumbnailImage = image
                }
            }
        }
    }
}

struct AddCard: View {
    let onTap: () -> Void

    private let cardWidth: CGFloat = 160
    private let cardHeight: CGFloat = 140
    private let thumbnailWidth: CGFloat = 140
    private let thumbnailHeight: CGFloat = 79

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: thumbnailWidth, height: thumbnailHeight)

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
            .frame(width: thumbnailWidth, height: thumbnailHeight)
            .onTapGesture(perform: onTap)

            Text("Add Video")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: cardWidth, height: cardHeight)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}
