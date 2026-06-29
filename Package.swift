// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ProcessKill",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ProcessKill", targets: ["ProcessKill"])
    ],
    targets: [
        .executableTarget(
            name: "ProcessKill"
        ),
        .testTarget(
            name: "ProcessKillTests",
            dependencies: ["ProcessKill"]
        )
    ]
)
