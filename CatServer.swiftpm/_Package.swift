// swift-tools-version:5.5
/*import PackageDescription
 
 let package = Package(
     name: "TinyWebFramework",
     platforms: [
         .macOS(.v10_15), .linux
     ],
     products: [
         .executable(name: "TinyWebApp", targets: ["TinyWebApp"])
     ],
     dependencies: [
         // SwiftNIO dependencies for Linux networking
         .package(url: "https://github.com/apple/swift-nio.git", from: "2.32.0")
     ],
     targets: [
         // Target for the executable
         .executableTarget(
             name: "TinyWebApp",
             dependencies: [
                 .product(name: "NIO", package: "swift-nio"),
                 .product(name: "NIOHTTP1", package: "swift-nio")
             ],
             path: ".",  // Points to the root directory for the target
             exclude: [
                 // Files excluded from Linux target
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
                 "WebApp.swift",
                 "Routes.swift",
                 "main.swift"
             ],
             resources: [
                 .copy("Resources/notes.json")  // Including JSON file in Resources
             ]
         )
     ]
 )*/
