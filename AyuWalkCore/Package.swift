// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AyuWalkCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "AyuWalkCore", targets: ["AyuWalkCore"])
    ],
    targets: [
        .target(name: "AyuWalkCore"),
        .testTarget(
            name: "AyuWalkCoreTests",
            dependencies: ["AyuWalkCore"]
        )
    ]
)
