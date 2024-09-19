// swift-tools-version:5.5
#if os(Linux)
import PackageDescription

let package = Package(
    name: "TinyWebFramework",
    platforms: [
        .linux
    ],
    products: [
        .executable(name: "LinuxApp", targets: ["LinuxApp"])
    ],
    dependencies: [
        // Add the NIO dependencies for the Linux project
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0")
    ],
    targets: [
        // Shared framework logic for the TinyWebFramework
        .target(
            name: "TinyWebFramework",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: "Sources/TinyWebFramework"
        ),
        // Linux-specific executable
        .executableTarget(
            name: "LinuxApp",
            dependencies: ["TinyWebFramework"],
            path: "Sources/LinuxApp"
        ),
        .testTarget(
            name: "TinyWebFrameworkTests",
            dependencies: ["TinyWebFramework"]
        )
    ]
)
#endif
