import Foundation

public func startWebApp(with webFramework: TinyWebFrameworkProtocol) {
    setupRoutes(webFramework: webFramework)
    webFramework.startServer(host: "127.0.0.1", port: 8080)
}
