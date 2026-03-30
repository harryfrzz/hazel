import AppKit
import Combine
import AVFoundation

class WallpaperController: ObservableObject {
    @Published private(set) var isActive: Bool = false
    
    private var wallpaperWindows: [NSScreen: (window: WallpaperWindow, playerView: VideoPlayerView)] = [:]
    private var store: WallpaperStore
    private var screenObserver: Any?
    private var sleepObserver: Any?
    private var wakeObserver: Any?

    init(store: WallpaperStore) {
        self.store = store
        setupNotifications()
    }

    deinit {
        removeNotifications()
    }

    private func setupNotifications() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }

        let workspace = NSWorkspace.shared
        let notificationCenter = workspace.notificationCenter

        sleepObserver = notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.pauseAll()
        }

        wakeObserver = notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.resumeIfNeeded()
        }
    }

    private func removeNotifications() {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func handleScreenChange() {
        let currentScreens = Set(NSScreen.screens)
        let existingScreens = Set(wallpaperWindows.keys)

        let screensToRemove = existingScreens.subtracting(currentScreens)
        for screen in screensToRemove {
            if let entry = wallpaperWindows.removeValue(forKey: screen) {
                entry.playerView.cleanup()
                entry.window.close()
            }
        }

        let screensToAdd = currentScreens.subtracting(existingScreens)
        for screen in screensToAdd {
            createWallpaperWindow(for: screen)
        }

        for (screen, entry) in wallpaperWindows {
            entry.window.setFrame(screen.frame, display: true)
        }

        resumeIfNeeded()
    }

    private func createWallpaperWindow(for screen: NSScreen) {
        let window = WallpaperWindow(screen: screen)
        let playerView = VideoPlayerView(frame: screen.frame)
        
        window.contentView = playerView
        window.orderFront(nil)
        
        print("Wallpaper window created for screen: \(screen.localizedName), visible: \(window.isVisible)")

        wallpaperWindows[screen] = (window, playerView)
    }

    func setWallpaper(_ item: WallpaperItem) {
        isActive = true

        for screen in NSScreen.screens {
            if wallpaperWindows[screen] == nil {
                createWallpaperWindow(for: screen)
            }
        }

        guard let url = store.resolveBookmark(item.url) else {
            print("Failed to resolve bookmark URL")
            return
        }

        for (_, entry) in wallpaperWindows {
            entry.playerView.loadVideo(url: url)
        }
    }

    func clearWallpaper() {
        isActive = false

        for (_, entry) in wallpaperWindows {
            entry.playerView.cleanup()
        }
    }

    func pauseAll() {
        for (_, entry) in wallpaperWindows {
            entry.playerView.pause()
        }
    }

    func resumeIfNeeded() {
        guard isActive else { return }

        for (_, entry) in wallpaperWindows {
            entry.playerView.play()
        }
    }
    
    func reloadCurrentWallpaper() {
        guard let activeItem = store.activeWallpaper,
              let url = store.resolveBookmark(activeItem.url) else { return }
        
        for (_, entry) in wallpaperWindows {
            entry.playerView.loadVideo(url: url, isLooping: activeItem.isLooping)
        }
    }
}
