// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BitChord",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BitChord",
            targets: ["BitChord"]
        ),
    ],
    dependencies: [
        // Add external dependencies here
        // For example:
        // .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    ],
    targets: [
        .target(
            name: "BitChord",
            dependencies: []
        ),
        .testTarget(
            name: "BitChordTests",
            dependencies: ["BitChord"]
        ),
    ]
)
