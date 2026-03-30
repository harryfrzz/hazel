import Foundation
import AVFoundation
import AppKit
import Combine

class WallpaperStore: ObservableObject {
    @Published var wallpapers: [WallpaperItem] = []
    var activeWallpaperID: UUID? {
        didSet {
            if let id = activeWallpaperID {
                UserDefaults.standard.set(id.uuidString, forKey: "activeWallpaperID")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeWallpaperID")
            }
        }
    }

    private let fileManager = FileManager.default
    
    private var appSupportURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("LiveWallpaper", isDirectory: true)
        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder
    }
    
    private var videosURL: URL {
        let videosFolder = appSupportURL.appendingPathComponent("Videos", isDirectory: true)
        try? fileManager.createDirectory(at: videosFolder, withIntermediateDirectories: true)
        return videosFolder
    }
    
    private var storageURL: URL {
        return appSupportURL.appendingPathComponent("wallpapers.json")
    }

    var activeWallpaper: WallpaperItem? {
        guard let id = activeWallpaperID else { return nil }
        return wallpapers.first { $0.id == id }
    }

    init() {
        if let idString = UserDefaults.standard.string(forKey: "activeWallpaperID"),
           let id = UUID(uuidString: idString) {
            activeWallpaperID = id
        }
        load()
    }

    func load() {
        guard fileManager.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoder = JSONDecoder()
            wallpapers = try decoder.decode([WallpaperItem].self, from: data)
            
            if let idString = UserDefaults.standard.string(forKey: "activeWallpaperID"),
               let id = UUID(uuidString: idString),
               wallpapers.contains(where: { $0.id == id }) {
                activeWallpaperID = id
            }
        } catch {
            print("Failed to load wallpapers: \(error)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(wallpapers)
            try data.write(to: storageURL)
        } catch {
            print("Failed to save wallpapers: \(error)")
        }
    }

    func addWallpaper(url: URL) -> WallpaperItem? {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to start accessing security scoped resource")
            return nil
        }

        defer { url.stopAccessingSecurityScopedResource() }

        let fileName = url.deletingPathExtension().lastPathComponent
        
        if wallpapers.contains(where: { $0.title == fileName }) {
            print("Video already exists: \(fileName)")
            return nil
        }

        let id = UUID()
        let title = fileName
        let videoExtension = url.pathExtension
        let destinationURL = videosURL.appendingPathComponent("\(id.uuidString).\(videoExtension)")

        do {
            try fileManager.copyItem(at: url, to: destinationURL)
        } catch {
            print("Failed to copy video: \(error)")
            return nil
        }

        let itemURL = destinationURL
        var item = WallpaperItem(url: itemURL, title: title)

        if let thumbnailPath = generateThumbnail(for: itemURL, id: id) {
            item.thumbnailPath = thumbnailPath
        }

        wallpapers.insert(item, at: 0)
        save()
        return item
    }

    func removeWallpaper(_ item: WallpaperItem) {
        if let index = wallpapers.firstIndex(where: { $0.id == item.id }) {
            if let thumbnailPath = wallpapers[index].thumbnailPath {
                try? fileManager.removeItem(atPath: thumbnailPath)
            }
            
            try? fileManager.removeItem(at: item.url)
            
            wallpapers.remove(at: index)
            save()
        }

        if activeWallpaperID == item.id {
            activeWallpaperID = nil
        }
    }

    func setActiveWallpaper(_ item: WallpaperItem) {
        activeWallpaperID = item.id
    }
    
    func toggleLoop(for item: WallpaperItem) {
        if let index = wallpapers.firstIndex(where: { $0.id == item.id }) {
            wallpapers[index].isLooping.toggle()
            save()
        }
    }
    
    func toggleMute(for item: WallpaperItem) {
        if let index = wallpapers.firstIndex(where: { $0.id == item.id }) {
            wallpapers[index].isMuted.toggle()
            save()
        }
    }

    func resolveBookmark(_ bookmarkURL: URL) -> URL? {
        guard fileManager.fileExists(atPath: bookmarkURL.path) else {
            print("File does not exist at path: \(bookmarkURL.path)")
            return nil
        }
        return bookmarkURL
    }

    private func generateThumbnail(for url: URL, id: UUID) -> String? {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let thumbnailsDir = cachesDir.appendingPathComponent("LiveWallpaper/Thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)

        let thumbnailPath = thumbnailsDir.appendingPathComponent("\(id.uuidString).png").path

        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 440, height: 248)

        let time = CMTime(seconds: 2, preferredTimescale: 600)

        var resultImage: CGImage?
        let semaphore = DispatchSemaphore(value: 0)

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, _ in
            resultImage = cgImage
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 10)

        guard let cgImage = resultImage else {
            return nil
        }

        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        if let tiffData = nsImage.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: URL(fileURLWithPath: thumbnailPath))
                return thumbnailPath
            } catch {
                print("Failed to write thumbnail: \(error)")
            }
        }

        return nil
    }

    func loadThumbnailImage(for item: WallpaperItem) -> NSImage? {
        guard let thumbnailPath = item.thumbnailPath else { return nil }
        let url = URL(fileURLWithPath: thumbnailPath)
        return NSImage(contentsOf: url)
    }
}
