//
//  BuatsaverError.swift
//  Buatsaver
//
//  Error types for the Buatsaver application.
//

import Foundation

enum BuatsaverError: LocalizedError {
    case invalidVideoFormat(String)
    case thumbnailGenerationFailed(String)
    case screensaverGenerationFailed(String)
    case invalidBundleIdentifier(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidVideoFormat(let format):
            return "Invalid video format: \(format). Please use MP4 or MOV files."
        case .thumbnailGenerationFailed(let details):
            return "Failed to generate thumbnail: \(details)"
        case .screensaverGenerationFailed(let details):
            return "Failed to create screensaver: \(details)"
        case .invalidBundleIdentifier(let identifier):
            return "Invalid bundle identifier format: \(identifier). Use alphanumeric characters, hyphens, underscores, and dots."
        }
    }
}