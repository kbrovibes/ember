// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Ember",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Ember", targets: ["Ember"]),
        .library(name: "EmberCore", targets: ["EmberCore"]),
    ],
    targets: [
        .target(name: "EmberCore", path: "Sources/EmberCore"),
        .executableTarget(name: "Ember", dependencies: ["EmberCore"], path: "Sources/Ember"),
        .testTarget(name: "EmberCoreTests", dependencies: ["EmberCore"], path: "Tests/EmberCoreTests"),
    ]
)
