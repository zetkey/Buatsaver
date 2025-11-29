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
        NSLog("Buatsaver: Bundle path: \(bundle.bundlePath)")
        NSLog("Buatsaver: Resources path: \(bundle.resourcePath ?? "nil")")

        // Try to find video.mp4 or video.mov
        if let mp4URL = bundle.url(forResource: "video", withExtension: "mp4") {
            videoURL = mp4URL
            NSLog("Buatsaver: Found video.mp4 at: \(mp4URL.path)")
        } else if let movURL = bundle.url(forResource: "video", withExtension: "mov") {
            videoURL = movURL
            NSLog("Buatsaver: Found video.mov at: \(movURL.path)")
        } else {
            NSLog("Buatsaver: ERROR - No video found in bundle!")
            NSLog("Buatsaver: Bundle resources: \(bundle.resourcePath ?? "none")")

            // List all files in Resources to debug
            if let resourcePath = bundle.resourcePath {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    NSLog("Buatsaver: Files in Resources: \(files)")
                } catch {
                    NSLog("Buatsaver: Error listing files: \(error)")
                }
            }

            // Set red background to indicate error
            if let layer = layer {
                layer.backgroundColor = NSColor.red.cgColor
            }
        }
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        guard let url = videoURL else {
            NSLog("Buatsaver: Cannot setup player - no video URL")
            return
        }

        guard let viewLayer = layer else {
            NSLog("Buatsaver: Cannot setup player - no view layer")
            return
        }

        NSLog("Buatsaver: Setting up player with video: \(url.path)")

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

        NSLog("Buatsaver: Player layer added with frame: \(newPlayerLayer.frame)")

        // Setup looping notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Observe player status
        player?.currentItem?.addObserver(self, forKeyPath: "status", options: [.new], context: nil)

        NSLog("Buatsaver: Player setup complete")
    }

    override func observeValue(
        forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "status" {
            if let statusNumber = change?[.newKey] as? NSNumber {
                let status = AVPlayerItem.Status(rawValue: statusNumber.intValue)
                NSLog("Buatsaver: Player status changed to: \(status?.rawValue ?? -1)")

                switch status {
                case .readyToPlay:
                    NSLog("Buatsaver: Player ready to play")
                case .failed:
                    if let error = player?.currentItem?.error {
                        NSLog("Buatsaver: Player failed with error: \(error)")
                        NSLog("Buatsaver: Error domain: \(error._domain)")
                        NSLog("Buatsaver: Error code: \(error._code)")
                        NSLog("Buatsaver: Error description: \(error.localizedDescription)")
                    } else {
                        NSLog("Buatsaver: Player failed with unknown error")
                    }
                case .unknown:
                    NSLog("Buatsaver: Player status unknown")
                default:
                    break
                }
            }
        }
    }

    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        NSLog("Buatsaver: Video reached end, looping...")
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: .zero, completionHandler: nil)
        player?.play()
    }

    // MARK: - Animation Lifecycle

    override func startAnimation() {
        super.startAnimation()
        NSLog("Buatsaver: startAnimation called")

        // Setup player if not already done
        if player == nil {
            setupPlayer()
        }

        // Start playing
        player?.play()
        NSLog("Buatsaver: Player play() called")
    }

    override func stopAnimation() {
        super.stopAnimation()
        NSLog("Buatsaver: stopAnimation called")
        player?.pause()
    }

    // MARK: - Layout

    override func draw(_ rect: NSRect) {
        super.draw(rect)
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
        NSLog("Buatsaver: Layout updated, player layer frame: \(playerLayer?.frame ?? .zero)")
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
