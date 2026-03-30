import Foundation

struct WallpaperItem: Codable, Identifiable, Equatable {
    let id: UUID
    let url: URL
    let title: String
    var thumbnailPath: String?
    var isLooping: Bool
    var isMuted: Bool

    init(id: UUID = UUID(), url: URL, title: String, thumbnailPath: String? = nil, isLooping: Bool = true, isMuted: Bool = true) {
        self.id = id
        self.url = url
        self.title = title
        self.thumbnailPath = thumbnailPath
        self.isLooping = isLooping
        self.isMuted = isMuted
    }

    static func == (lhs: WallpaperItem, rhs: WallpaperItem) -> Bool {
        lhs.id == rhs.id
    }
}
