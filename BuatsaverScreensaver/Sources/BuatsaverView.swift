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
import IOKit.pwr_mgt
import ScreenSaver

@objc(BuatsaverView)
@objcMembers
@MainActor
class BuatsaverView: ScreenSaverView {

    private var playerLayer: AVPlayerLayer?
    private var player: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var videoURL: URL?
    private var noSleepAssertionID: IOPMAssertionID = IOPMAssertionID(0)

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

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            // Prevent display sleep while screensaver is active
            IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Buatsaver is running" as CFString,
                &noSleepAssertionID
            )
        } else {
            // Release the assertion when the view is removed
            if noSleepAssertionID != kIOPMNullAssertionID {
                IOPMAssertionRelease(noSleepAssertionID)
                noSleepAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
            }
        }
    }

    deinit {
        // Remove any remaining notifications
        NotificationCenter.default.removeObserver(self)

        // Ensure cleanup happens on main thread
        MainActor.assumeIsolated { [weak self] in
            self?.tearDownPlayer()
        }
    }

    @MainActor
    private func tearDownPlayer() {
        // Stop playback first
        player?.pause()
        player?.rate = 0

        // CRITICAL: Invalidate looper to break retain cycle
        playerLooper?.disableLooping()
        playerLooper = nil

        // Cancel pending operations
        player?.currentItem?.cancelPendingSeeks()
        player?.currentItem?.asset.cancelLoading()

        // Remove notifications
        NotificationCenter.default.removeObserver(self)

        // Clean up layers and references
        playerLayer?.player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil

        // Remove all items from queue player
        if let queuePlayer = player {
            queuePlayer.removeAllItems()
        }

        // Release player reference
        player = nil
    }

    // MARK: - Video Discovery

    private func findVideo() {
        let bundle = Bundle(for: type(of: self))

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let videoURL: URL?

            if let mp4URL = bundle.url(forResource: "video", withExtension: "mp4") {
                videoURL = mp4URL
            } else if let movURL = bundle.url(forResource: "video", withExtension: "mov") {
                videoURL = movURL
            } else {
                videoURL = nil
            }

            DispatchQueue.main.async {
                self?.videoURL = videoURL
                if videoURL != nil {
                    self?.setupPlayer()
                } else {
                    self?.layer?.backgroundColor = NSColor.red.cgColor
                }
            }
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

        // Optimize buffering for smooth playback
        playerItem.preferredForwardBufferDuration = 10.0

        // Create queue player for seamless looping
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.volume = 0
        queuePlayer.automaticallyWaitsToMinimizeStalling = true  // CRITICAL: prevents stuttering
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = false

        // Configure player layer with background to prevent black flashes
        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.black.cgColor  // Prevent white/transparent flashes
        playerLayer.needsDisplayOnBoundsChange = true
        playerLayer.contentsGravity = .resizeAspectFill
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        // Setup references
        self.player = queuePlayer
        self.playerLayer = playerLayer
        viewLayer.addSublayer(playerLayer)

        // Setup seamless looping with AVPlayerLooper using time range
        // This ensures the entire video duration is used for looping
        let duration = asset.duration
        let timeRange = CMTimeRange(start: .zero, duration: duration)
        let playerLooper = AVPlayerLooper(
            player: queuePlayer, templateItem: playerItem, timeRange: timeRange)
        self.playerLooper = playerLooper

        // Start playback
        queuePlayer.play()
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
