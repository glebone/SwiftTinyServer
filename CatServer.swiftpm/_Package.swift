// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "TinyWebFramework",
    products: [
        .executable(name: "TinyWebApp", targets: ["TinyWebApp"])
    ],
    dependencies: [
        // NIO dependencies for Linux
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.32.0")
    ],
    targets: [
        // Combined target for the executable
        .executableTarget(
            name: "TinyWebApp",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: ".",
            exclude: [
                "ContentView.swift",
                "LinuxLaunch.swift",
                "MyApp.swift",
                "TinyWebFramework+iPad.swift"
            ],
            sources: [
                "TinyWebFramework.swift",
                "TinyWebFramework+Linux.swift",
                "Model.swift",
                "NoteModel.swift",
                "Webapp.swift",
                "main.swift"
            ],
            resources: [
                .copy("Resources/notes.json")
            ]
        )
    ]
)