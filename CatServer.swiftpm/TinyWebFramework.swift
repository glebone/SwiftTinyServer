import Foundation

public protocol TinyWebFrameworkProtocol {
    func startServer(host: String, port: Int)
    func stopServer()
    func addRoute(_ path: String, handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void)
    func loadHTMLTemplate(named fileName: String) throws -> String
}

// Ensure HTTPRequest and HTTPResponse are public
public struct HTTPRequest {
    public let method: String
    public let path: String
    public let headers: [String: String]
    public let body: Data
}

public struct HTTPResponse {
    public var statusCode: Int
    public var headers: [String: String]
    public var body: Data
}

extension TinyWebFrameworkProtocol {
    
   public  func loadHTMLTemplate(named fileName: String) throws -> String {
        #if os(macOS) || os(iOS)
        // Try to locate the file in the app bundle on macOS/iOS
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            throw NSError(domain: "TinyWebFramework", code: 1, userInfo: [NSLocalizedDescriptionKey: "The file \(fileName) couldn't be found."])
        }
        #else
        // On Linux, look in the local directory or other specified location
        let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources").appendingPathComponent(fileName)
        #endif

        do {
            let htmlContent = try String(contentsOf: fileURL, encoding: .utf8)
            return htmlContent
        } catch {
            throw NSError(domain: "TinyWebFramework", code: 2, userInfo: [NSLocalizedDescriptionKey: "The file \(fileName) couldn't be opened. Error: \(error)"])
        }
        }
    
    private func getWorkingDirectory() -> URL {
        // Use current directory on Linux and the document directory on iOS/macOS
        #if os(Linux)
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        #else
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        #endif
    }
    
   
        
}
