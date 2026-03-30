import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Constants
private enum AppConstants {
    static let githubURL = URL(string: "https://github.com/harryfrzz/hazel")!
    static let donateURL = URL(string: "https://www.buymeacoffee.com/")!
    static let allowedMovieTypes: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie]
}

// MARK: - View
struct ManagementView: View {
    @ObservedObject var store: WallpaperStore
    @ObservedObject var controller: WallpaperController
    
    @State private var showingFileImporter = false
    @State private var showingDuplicateAlert = false
    @State private var duplicateVideoName = ""
    
    var body: some View {
        VStack(spacing: 16) {
            headerSection
            Spacer()
            wallpaperScrollView
        }
        .padding(.vertical, 20)
        .frame(width: 600, height: 340)
        // Using a modern macOS material background instead of a flat color
        .background(Material.regular)
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 120)
                .padding(.leading, 20)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 12) {
                Text("Hazel")
                    .font(.custom("GeistPixel-Square", size: 28))
                
                HStack(spacing: 12) {
                    Link(destination: AppConstants.githubURL) {
                        Label("GitHub", systemImage: "link")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .help("Visit the GitHub repository")
                    
                    Link(destination: AppConstants.donateURL) {
                        Label("Donate", systemImage: "heart.fill")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.pink.opacity(0.2))
                    .foregroundColor(.pink)
                    .cornerRadius(8)
                    .help("Support the developer")
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 20)
    }
    
    private var wallpaperScrollView: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(spacing: 16) {
                AddCard {
                    showingFileImporter = true
                }
                .fileImporter(
                    isPresented: $showingFileImporter,
                    allowedContentTypes: AppConstants.allowedMovieTypes,
                    allowsMultipleSelection: true,
                    onCompletion: handleFileImport
                )
                
                ForEach(store.wallpapers) { item in
                    WallpaperCard(
                        item: item,
                        isSelected: store.activeWallpaperID == item.id,
                        onTap: {
                            store.setActiveWallpaper(item)
                            controller.setWallpaper(item)
                        },
                        onRemove: {
                            if store.activeWallpaperID == item.id {
                                controller.clearWallpaper()
                            }
                            // Add slight animation when removing items
                            withAnimation(.easeInOut(duration: 0.2)) {
                                store.removeWallpaper(item)
                            }
                        },
                        onToggleLoop: {
                            store.toggleLoop(for: item)
                            if store.activeWallpaperID == item.id,
                               let updatedItem = store.wallpapers.first(where: { $0.id == item.id }) {
                                controller.setWallpaper(updatedItem)
                            }
                        },
                        onToggleMute: {
                            store.toggleMute(for: item)
                            if store.activeWallpaperID == item.id,
                               let updatedItem = store.wallpapers.first(where: { $0.id == item.id }) {
                                controller.setWallpaper(updatedItem)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Actions
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            var lastAddedItem: WallpaperItem?
            
            // If user imports 5 videos, we don't want to trigger setWallpaper 5 times rapidly.
            // We add them all, and only set the LAST one as active.
            for url in urls {
                if let item = store.addWallpaper(url: url) {
                    lastAddedItem = item
                }
            }
            
            if let itemToActivate = lastAddedItem {
                store.setActiveWallpaper(itemToActivate)
                controller.setWallpaper(itemToActivate)
            }
            
        case .failure(let error):
            // In a production app, consider showing an NSAlert or an Alert view here
            print("File import error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Window Controller
class ManagementWindowController: NSObject, NSWindowDelegate {
    private var panel: NSPanel?
    
    func showPanel(store: WallpaperStore, controller: WallpaperController) {
        if let existingPanel = panel {
            existingPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let hostingView = NSHostingView(rootView: ManagementView(store: store, controller: controller))
        
        // Modern macOS Window Styling
        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 340),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        newPanel.title = "hazel"
        newPanel.titleVisibility = .hidden // Hides the text title for a cleaner look
        newPanel.titlebarAppearsTransparent = true // Merges the titlebar with the content
        newPanel.isMovableByWindowBackground = true // User can drag the window from anywhere
        newPanel.contentView = hostingView
        newPanel.isReleasedWhenClosed = false
        newPanel.level = .floating // Keeps it above other windows
        newPanel.center()
        newPanel.delegate = self
        
        panel = newPanel
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closePanel() {
        panel?.close()
    }
    
    // Listen for the user clicking the red 'X' button
    func windowWillClose(_ notification: Notification) {
        panel = nil
    }
}
