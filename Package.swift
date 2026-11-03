// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanBar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CleanBar", targets: ["CleanBar"])
    ],
    targets: [
        .executableTarget(
            name: "CleanBar",
            path: "Sources/CleanBar"
        ),
        .testTarget(
            name: "CleanBarTests",
            dependencies: ["CleanBar"],
            path: "Tests/CleanBarTests"
        )
    ]
)
