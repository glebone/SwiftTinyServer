// TinyWebFramework+iPad.swift
#if os(macOS) || os(iOS)
import Foundation
import Network

class TinyWebFramework: NSObject, TinyWebFrameworkProtocol {
    private var listener: NWListener?
    private var routes: [String: (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void] = [:]
    
    func startServer(host: String = "127.0.0.1", port: Int = 8080) {
        let params = NWParameters.tcp
        let queue = DispatchQueue(label: "ServerQueue")
        do {
            listener = try NWListener(using: params, on: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)))
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            listener?.start(queue: queue)
            print("Server started and listening on port \(port)")
        } catch {
            print("Failed to create listener: \(error)")
        }
    }
    
    func stopServer() {
        listener?.cancel()
        listener = nil
        print("Server stopped")
    }
    
    func addRoute(_ path: String, handler: @escaping (HTTPRequest, @escaping (HTTPResponse) -> Void) -> Void) {
        routes[path] = handler
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        receiveRequest(connection: connection)
    }
    
    private func receiveRequest(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] (data, context, isComplete, error) in
            guard let self = self else { return }
            if let data = data, !data.isEmpty, let requestString = String(data: data, encoding: .utf8) {
                let request = self.parseRequest(from: requestString)
                if let handler = self.routes[request.path] {
                    handler(request) { response in
                        self.sendResponse(connection: connection, response: response)
                    }
                } else {
                    self.sendNotFound(connection: connection)
                }
            }
            if isComplete {
                connection.cancel()
            } else if error == nil {
                self.receiveRequest(connection: connection)
            }
        }
    }
    
    private func sendResponse(connection: NWConnection, response: HTTPResponse) {
        var responseString = "HTTP/1.1 \(response.statusCode) \(self.statusMessage(for: response.statusCode))\r\n"
        for (header, value) in response.headers {
            responseString += "\(header): \(value)\r\n"
        }
        responseString += "Content-Length: \(response.body.count)\r\n"
        responseString += "\r\n"
        
        var responseData = responseString.data(using: .utf8) ?? Data()
        responseData.append(response.body)
        
        connection.send(content: responseData, completion: .contentProcessed { error in
            if let error = error {
                print("Failed to send response: \(error)")
            }
            connection.cancel()
        })
    }
    
    private func sendNotFound(connection: NWConnection) {
        let response = HTTPResponse(
            statusCode: 404,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: "<h1>404 Not Found</h1>".data(using: .utf8) ?? Data()
        )
        sendResponse(connection: connection, response: response)
    }
    
    private func parseRequest(from requestString: String) -> HTTPRequest {
        let lines = requestString.components(separatedBy: "\r\n")
        let requestLine = lines.first ?? ""
        let components = requestLine.components(separatedBy: " ")
        let method = components.count > 0 ? components[0] : "GET"
        let path = components.count > 1 ? components[1] : "/"
        
        var headers = [String: String]()
        var index = 1
        while index < lines.count && lines[index] != "" {
            let headerLine = lines[index]
            if let separatorRange = headerLine.range(of: ": ") {
                let headerName = String(headerLine[..<separatorRange.lowerBound])
                let headerValue = String(headerLine[separatorRange.upperBound...])
                headers[headerName] = headerValue
            }
            index += 1
        }
        
        var body = Data()
        if let bodyStartIndex = requestString.range(of: "\r\n\r\n")?.upperBound {
            let bodyString = String(requestString[bodyStartIndex...])
            body = bodyString.data(using: .utf8) ?? Data()
        }
        
        return HTTPRequest(method: method, path: path, headers: headers, body: body)
    }
    
    private func statusMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 200: return "OK"
        case 201: return "Created"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 500: return "Internal Server Error"
        default: return "HTTP Status \(statusCode)"
        }
    }
}
#endif
