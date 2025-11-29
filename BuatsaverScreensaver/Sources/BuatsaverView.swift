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
import ScreenSaver

@objc(BuatsaverView)
@objcMembers
class BuatsaverView: ScreenSaverView {

    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var videoURL: URL?

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
        NotificationCenter.default.removeObserver(self)
        player?.pause()
        playerLayer?.removeFromSuperlayer()
    }

    // MARK: - Video Discovery

    private func findVideo() {
        let bundle = Bundle(for: type(of: self))

        // Try to find video.mp4 or video.mov
        if let mp4URL = bundle.url(forResource: "video", withExtension: "mp4") {
            videoURL = mp4URL
        } else if let movURL = bundle.url(forResource: "video", withExtension: "mov") {
            videoURL = movURL
        } else {
            NSLog(
                "Buatsaver ERROR: No video found in bundle at \(bundle.resourcePath ?? "unknown path")"
            )

            // Set red background to indicate error
            if let layer = layer {
                layer.backgroundColor = NSColor.red.cgColor
            }
        }
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        guard let url = videoURL, let viewLayer = layer else {
            NSLog("Buatsaver ERROR: Cannot setup player")
            return
        }

        // Create player
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.actionAtItemEnd = .none
        player?.isMuted = true

        // Create player layer
        let newPlayerLayer = AVPlayerLayer(player: player)
        newPlayerLayer.frame = bounds
        newPlayerLayer.videoGravity = .resizeAspectFill
        newPlayerLayer.backgroundColor = NSColor.black.cgColor

        // Remove old layer if exists
        playerLayer?.removeFromSuperlayer()

        // Add new layer
        viewLayer.addSublayer(newPlayerLayer)
        playerLayer = newPlayerLayer

        // Setup looping notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Observe player status
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
    }

    override func observeValue(
        forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "status" {
            if let statusNumber = change?[.newKey] as? NSNumber {
                let status = AVPlayerItem.Status(rawValue: statusNumber.intValue)

                if status == .failed, let error = player?.currentItem?.error {
                    NSLog("Buatsaver ERROR: Player failed - \(error.localizedDescription)")
                }
            }
        }
    }

    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: .zero, completionHandler: nil)
        player?.play()
    }

    // MARK: - Animation Lifecycle

    override func startAnimation() {
        super.startAnimation()

        // Setup player if not already done
        if player == nil {
            setupPlayer()
        }

        // Start playing
        player?.play()
    }

    override func stopAnimation() {
        super.stopAnimation()
        player?.pause()
    }

    // MARK: - Layout

    override func draw(_ rect: NSRect) {
        super.draw(rect)
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    override var frame: NSRect {
        didSet {
            playerLayer?.frame = bounds
        }
    }

    // MARK: - Configuration

    override var hasConfigureSheet: Bool {
        return false
    }

    override var configureSheet: NSWindow? {
        return nil
    }
}
