//
//  BuatsaverApp.swift
//  Buatsaver
//
//  A macOS application for creating custom video screensavers.
//

import SwiftUI

@main
struct BuatsaverApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
