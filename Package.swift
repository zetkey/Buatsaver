// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Buatsaver",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "BuatsaverScreensaver", targets: ["BuatsaverScreensaver"]),
        .executable(name: "BuatsaverApp", targets: ["BuatsaverApp"])
    ],
    targets: [
        .target(
            name: "BuatsaverScreensaver",
            path: "BuatsaverScreensaver/Sources",
            publicHeadersPath: "."
        ),
        .executableTarget(
            name: "BuatsaverApp",
            dependencies: [],
            path: "BuatsaverApp/Sources"
        )
    ]
)