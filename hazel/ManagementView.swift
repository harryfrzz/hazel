import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ManagementView: View {
    @ObservedObject var store: WallpaperStore
    @ObservedObject var controller: WallpaperController

    @State private var showingFileImporter = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    AddCard {
                        showingFileImporter = true
                    }
                    .fileImporter(
                        isPresented: $showingFileImporter,
                        allowedContentTypes: [
                            UTType.movie,
                            UTType.mpeg4Movie,
                            UTType.quickTimeMovie
                        ],
                        allowsMultipleSelection: true
                    ) { result in
                        handleFileImport(result)
                    }

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
                                store.removeWallpaper(item)
                            },
                            onToggleLoop: {
                                store.toggleLoop(for: item)
                                if let updatedItem = store.wallpapers.first(where: { $0.id == item.id }),
                                   store.activeWallpaperID == item.id {
                                    controller.setWallpaper(updatedItem)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 600, height: 200)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                if let item = store.addWallpaper(url: url) {
                    store.setActiveWallpaper(item)
                    controller.setWallpaper(item)
                }
            }
        case .failure(let error):
            print("File import error: \(error)")
        }
    }
}

class ManagementWindowController: NSObject {
    private var panel: NSPanel?

    func showPanel(store: WallpaperStore, controller: WallpaperController) {
        if let existingPanel = panel {
            existingPanel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingView = NSHostingView(rootView: ManagementView(store: store, controller: controller))
        hostingView.frame = NSRect(x: 0, y: 0, width: 600, height: 200)

        let newPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 200),
            styleMask: [.titled, .closable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        newPanel.title = "hazel"
        newPanel.contentView = hostingView
        newPanel.isReleasedWhenClosed = false
        newPanel.level = .floating
        newPanel.center()

        panel = newPanel
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closePanel() {
        panel?.close()
        panel = nil
    }
}
