import AppKit

class WallpaperWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.setFrame(screen.frame, display: true)
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.ignoresMouseEvents = true
        self.isOpaque = true
        self.hasShadow = false
        self.backgroundColor = .black
        self.isReleasedWhenClosed = false
        self.alphaValue = 1.0
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
