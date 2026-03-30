import AppKit
import AVFoundation

class VideoPlayerView: NSView {
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var currentURL: URL?
    private var currentIsLooping: Bool = true

    var isPlaying: Bool {
        player?.rate ?? 0 > 0
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadVideo(url: URL, isLooping: Bool = true) {
        cleanup()
        currentURL = url
        currentIsLooping = isLooping

        var securityScoped = false
        if url.startAccessingSecurityScopedResource() {
            securityScoped = true
        }

        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        
        let fit = SettingsManager.shared.wallpaperFit
        
        if isLooping {
            let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            self.playerLooper = looper
        }

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.videoGravity = fit.videoGravity
        layer.frame = bounds

        self.layer?.addSublayer(layer)

        self.player = queuePlayer
        self.playerLayer = layer

        if securityScoped {
            url.stopAccessingSecurityScopedResource()
        }

        queuePlayer.play()
    }
    
    func reloadWithSettings() {
        guard let url = currentURL else { return }
        loadVideo(url: url, isLooping: currentIsLooping)
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func cleanup() {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        playerLooper?.disableLooping()
        playerLooper = nil
        player = nil
        playerLayer = nil
        currentURL = nil
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    deinit {
        cleanup()
    }
}
