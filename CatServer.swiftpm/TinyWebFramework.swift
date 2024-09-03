import Foundation
import Network

class TinyWebFramework: ObservableObject {
    private var routes: [String: (NWConnection, String) -> Void] = [:]
    private var listener: NWListener?
    
    func addRoute(_ path: String, handler: @escaping (NWConnection, String) -> Void) {
        routes[path] = handler
    }
    
    func startServer() {
        let queue = DispatchQueue(label: "ServerQueue")
        do {
            listener = try NWListener(using: .tcp, on: 8080)
            print("Server started and listening on port 8080")
        } catch {
            print("Failed to create listener: \(error)")
            return
        }
        
        listener?.newConnectionHandler = { newConnection in
            newConnection.start(queue: queue)
            newConnection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { (data, context, isComplete, error) in
                if let data = data, let request = String(data: data, encoding: .utf8) {
                    let path = self.parsePath(from: request)
                    print("Received request for path: \(path)")
                    self.handleRequest(newConnection, path: path, request: request)
                }
            }
        }
        
        listener?.start(queue: queue)
    }
    
    func stopServer() {
        listener?.cancel()
        print("Server stopped")
    }
    
    private func handleRequest(_ connection: NWConnection, path: String, request: String) {
        if let handler = routes[path] {
            handler(connection, request)
        } else {
            let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n"
            print("No route found for path: \(path)")
            connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                connection.cancel()
                print("Connection closed after 404 response")
            }))
        }
    }
    
    func parsePath(from request: String) -> String {
        let requestLines = request.split(separator: "\n")
        let requestLine = requestLines.first ?? ""
        let components = requestLine.split(separator: " ")
        return components.count > 1 ? String(components[1]) : "/"
    }
    
    func parseMethod(from request: String) -> String {
        let requestLines = request.split(separator: "\n")
        let requestLine = requestLines.first ?? ""
        let components = requestLine.split(separator: " ")
        return components.count > 0 ? String(components[0]) : "GET"
    }
    
    func parseBody(from request: String) -> [String: String]? {
        guard let bodyStartIndex = request.range(of: "\r\n\r\n")?.upperBound else {
            print("Failed to find body in request")
            return nil
        }
        let body = String(request[bodyStartIndex...])
        do {
            let json = try JSONSerialization.jsonObject(with: Data(body.utf8), options: []) as? [String: String]
            print("Successfully parsed body: \(String(describing: json))")
            return json
        } catch {
            print("Failed to parse JSON body: \(error)")
            return nil
        }
    }
}
