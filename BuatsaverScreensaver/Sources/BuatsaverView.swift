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

    private static let bundledVideoURL: URL? = {
        let bundle = Bundle(for: BuatsaverView.self)
        return bundle.url(forResource: "video", withExtension: "mp4")
            ?? bundle.url(forResource: "video", withExtension: "mov")
    }()

    // MARK: - Power Management

    @MainActor
    private func acquireDisplaySleepAssertion() {
        guard noSleepAssertionID == kIOPMNullAssertionID else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Buatsaver is running" as CFString,
            &noSleepAssertionID
        )

        if result != kIOReturnSuccess {
            noSleepAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
        }
    }

    @MainActor
    private func releaseDisplaySleepAssertion() {
        guard noSleepAssertionID != kIOPMNullAssertionID else { return }
        IOPMAssertionRelease(noSleepAssertionID)
        noSleepAssertionID = IOPMAssertionID(kIOPMNullAssertionID)
    }

    // MARK: - Initialization

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = .greatestFiniteMagnitude  // Disable ScreenSaver timer; AVPlayer drives frames
        wantsLayer = true

        // Set background color
        if let layer = layer {
            layer.backgroundColor = NSColor.black.cgColor
        }

        findVideo()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        animationTimeInterval = .greatestFiniteMagnitude  // Disable ScreenSaver timer; AVPlayer drives frames
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
            acquireDisplaySleepAssertion()
        } else {
            releaseDisplaySleepAssertion()
        }
    }

    deinit {
        // Remove any remaining notifications
        NotificationCenter.default.removeObserver(self)

        // Ensure cleanup happens on main thread
        MainActor.assumeIsolated { [weak self] in
            self?.releaseDisplaySleepAssertion()
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
        player?.removeAllItems()

        // Release player reference
        player = nil

        // Release any outstanding power assertions
        releaseDisplaySleepAssertion()
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

        acquireDisplaySleepAssertion()

        if player == nil {
            setupPlayer()
        } else {
            player?.play()
        }
    }

    public override func stopAnimation() {
        super.stopAnimation()

        // CRITICAL: Properly tear down player to prevent memory leaks and hanging process
        releaseDisplaySleepAssertion()
        tearDownPlayer()
    }

    // MARK: - Layout

    public override func draw(_ rect: NSRect) {
        super.draw(rect)
    }

    public override func animateOneFrame() {
        // Intentionally left blank. AVPlayer handles all visual updates, so we disable the timer.
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
