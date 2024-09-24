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
    
    public func loadHTMLTemplate(named fileName: String) throws -> String {
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
    
    public func parseFormData(from body: Data) -> [String: String]? {
        guard let bodyString = String(data: body, encoding: .utf8) else {
            return nil
        }
        
        let formData = bodyString.split(separator: "&").reduce(into: [String: String]()) { result, keyValuePair in
            let pair = keyValuePair.split(separator: "=")
            if pair.count == 2, let key = pair.first?.removingPercentEncoding, let value = pair.last?.removingPercentEncoding {
                // Replace '+' with space as part of decoding URL-encoded form data
                result[key] = value.replacingOccurrences(of: "+", with: " ")
            }
        }
        return formData
    }
    
    public func jsonResponse<T: Encodable>(statusCode: Int, object: T, responseHandler: @escaping (HTTPResponse) -> Void) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(object)
            let response = HTTPResponse(
                statusCode: statusCode,
                headers: ["Content-Type": "application/json"],
                body: data
            )
            responseHandler(response)
        } catch {
            let response = HTTPResponse(
                statusCode: 500,
                headers: ["Content-Type": "text/plain"],
                body: "Error encoding data.".data(using: .utf8) ?? Data()
            )
            responseHandler(response)
        }
    }
    
    public func errorResponse(statusCode: Int, message: String, responseHandler: @escaping (HTTPResponse) -> Void) {
        let response = HTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "text/plain"],
            body: message.data(using: .utf8) ?? Data()
        )
        responseHandler(response)
    }
}
