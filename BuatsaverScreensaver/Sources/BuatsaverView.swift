//
//  BuatsaverView.swift
//  BuatsaverScreensaver
//
//  A Swift-based screensaver view that plays a video file in a loop.
//  Supports both .mp4 and .mov video formats.
//

import AVFoundation
import AVKit
import Cocoa
import Quartz
import ScreenSaver

@objc(BuatsaverView)
@objcMembers
@MainActor
class BuatsaverView: ScreenSaverView {

    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playbackObserver: NSObjectProtocol?
    private var videoURL: URL?
    private let startTime = Date()

    private static let bundledVideoURL: URL? = {
        let bundle = Bundle(for: BuatsaverView.self)
        return bundle.url(forResource: "video", withExtension: "mp4")
            ?? bundle.url(forResource: "video", withExtension: "mov")
    }()

    // MARK: - Initialization

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 30.0
        wantsLayer = true

        // Set background color
        if let layer = layer {
            layer.backgroundColor = NSColor.black.cgColor
        }

        findVideo()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = 1.0 / 30.0
        wantsLayer = true

        // Set background color
        if let layer = layer {
            layer.backgroundColor = NSColor.black.cgColor
        }

        findVideo()
    }

    deinit {
        // Remove self from notifications
        NotificationCenter.default.removeObserver(self)

        Task { @MainActor [weak self] in
            self?.tearDownPlayer()
        }
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window == nil {
            tearDownPlayer()
        }
    }

    @MainActor
    private func tearDownPlayer() {
        // Stop playback first
        player?.pause()
        player?.rate = 0

        // Remove looping observer
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackObserver = nil
        }

        // Cancel pending operations
        player?.currentItem?.cancelPendingSeeks()
        player?.currentItem?.asset.cancelLoading()

        // Remove notifications
        NotificationCenter.default.removeObserver(self)

        // Clean up layers and references
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil

        // Release player reference
        player?.replaceCurrentItem(with: nil)
        player = nil

    }

    // MARK: - Video Discovery

    private func findVideo() {
        let url = Self.bundledVideoURL
        videoURL = url

        if url != nil {
            setupPlayer()
        } else {
            layer?.backgroundColor = NSColor.red.cgColor
        }
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        guard let url = videoURL, let viewLayer = layer else { return }

        // Remove old player first
        tearDownPlayer()

        // Configure asset with preloaded keys for optimal performance
        let asset = AVAsset(url: url)
        let keys = ["playable", "duration", "tracks"]

        // Create player item with preloaded asset keys
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: keys)
        playerItem.preferredForwardBufferDuration = 10.0
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = false

        // Create player for seamless looping
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = true
        player.preventsDisplaySleepDuringVideoPlayback = false

        // Configure player layer with background to prevent black flashes
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.black.cgColor  // Prevent white/transparent flashes
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.contentsGravity = .resizeAspectFill
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        // Setup references
        self.player = player
        self.playerLayer = playerLayer
        viewLayer.addSublayer(playerLayer)

        playbackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let player = self?.player else { return }
                player.seek(to: .zero)
                player.play()
            }
        }

        // Start playback
        player.play()
    }

    // MARK: - Animation Lifecycle

    public override func startAnimation() {
        super.startAnimation()

        if player == nil {
            setupPlayer()
        } else {
            player?.play()
        }
    }

    public override func stopAnimation() {
        super.stopAnimation()

        // CRITICAL: Properly tear down player to prevent memory leaks and hanging process
        tearDownPlayer()
    }

    // MARK: - Layout

    public override func draw(_ rect: NSRect) {
        super.draw(rect)
    }

    public override func animateOneFrame() {
        // Workaround for legacyScreenSaver process hanging
        // Check if user is active and screen is unlocked -> Force exit
        guard !isPreview else { return }

        // Wait 2 seconds before checking to allow startup
        if Date().timeIntervalSince(startTime) > 2.0 {
            let idleTime = getSystemIdleTime()
            let screenLocked = isScreenLocked()

            // If user moved mouse (idle < 1.0s) and screen is NOT locked, it means we should stop.
            // CAUTION: This kills the process. Only run if !isPreview.
            if idleTime < 1.0 && !screenLocked {
                // Stop player first
                tearDownPlayer()
                // Force exit process to prevent hanging
                exit(0)
            }
        }
    }

    // MARK: - Workaround Helpers

    private func getSystemIdleTime() -> TimeInterval {
        // CGEventSource.secondsSinceLastEventType handles HID idle time
        return CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: .mouseMoved)
    }

    private func isScreenLocked() -> Bool {
        // Check CGSession dictionary for screen lock status
        guard let sessionDict = CGSessionCopyCurrentDictionary() as? [String: Any] else {
            return false
        }

        if let isLocked = sessionDict["CGSSessionScreenIsLocked"] as? Bool {
            return isLocked
        }

        return false
    }

    public override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    public override var frame: NSRect {
        didSet {
            playerLayer?.frame = bounds
        }
    }

    // MARK: - Configuration

    public override var hasConfigureSheet: Bool {
        return false
    }

    public override var configureSheet: NSWindow? {
        return nil
    }
}
