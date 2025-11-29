//
//  ValidationUtility.swift
//  Buatsaver
//
//  Utility functions for validation.
//

import Foundation

struct ValidationUtility {
    static func isValidBundleIdentifier(_ identifier: String) -> Bool {
        guard !identifier.isEmpty else { return true } // Empty is valid since we auto-generate
        let pattern = "^[a-zA-Z0-9]([a-zA-Z0-9\\-_.]*[a-zA-Z0-9])?$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: identifier)
    }
    
    static func validateBundleIdentifier(_ identifier: String) throws {
        guard isValidBundleIdentifier(identifier) else {
            throw BuatsaverError.invalidBundleIdentifier(identifier)
        }
    }
}