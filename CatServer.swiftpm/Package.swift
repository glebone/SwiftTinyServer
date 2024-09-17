// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "CatServer",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    products: [
        .executable(
            name: "CatServer",
            targets: ["CatServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "CatServer",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "NIOFoundationCompat", package: "swift-nio"), // Include this line
            ],
            path: ".",
            exclude: ["Resources"] // Exclude Resources if you have that directory
        ),
    ]
)
