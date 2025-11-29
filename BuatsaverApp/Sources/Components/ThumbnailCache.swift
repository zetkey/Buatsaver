//
//  ThumbnailCache.swift
//  Buatsaver
//
//  Cache for video thumbnails to avoid regenerating them unnecessarily.
//

import AppKit
import AVFoundation

class ThumbnailCache: @unchecked Sendable {
    private let cache = NSCache<NSString, NSImage>()
    private let cacheQueue = DispatchQueue(label: "thumbnailCacheQueue", qos: .utility)
    
    static let shared = ThumbnailCache()
    
    private init() {
        // Limit memory usage
        cache.countLimit = 10
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    }
    
    func getThumbnail(for url: URL) -> NSImage? {
        return cacheQueue.sync {
            return cache.object(forKey: url.path as NSString)
        }
    }
    
    func setThumbnail(_ image: NSImage, for url: URL) {
        cacheQueue.async {
            self.cache.setObject(image, forKey: url.path as NSString)
        }
    }
    
    func removeThumbnail(for url: URL) {
        cacheQueue.async {
            self.cache.removeObject(forKey: url.path as NSString)
        }
    }
    
    func clearCache() {
        cacheQueue.async {
            self.cache.removeAllObjects()
        }
    }
}
