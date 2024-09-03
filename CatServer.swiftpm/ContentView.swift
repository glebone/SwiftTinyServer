import SwiftUI

struct ContentView: View {
    @StateObject private var webFramework = TinyWebFramework()
    private let noteModel = NoteModel()
    
    var body: some View {
        VStack {
            Text("Tiny Swift Web Server")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                setupRoutes()
                webFramework.startServer()
            }) {
                Text("Start Server")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Button(action: {
                webFramework.stopServer()
            }) {
                Text("Stop Server")
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
    
    func setupRoutes() {
        webFramework.addRoute("/") { connection, _ in
            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Hello, World!</h1>"
            connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                connection.cancel()
                print("Handled / route with Hello, World!")
            }))
        }
        
        webFramework.addRoute("/note") { connection, request in
            let method = webFramework.parseMethod(from: request)
            print("Handling /note route with method: \(method)")
            
            if method == "POST" {
                guard let note = webFramework.parseBody(from: request) else {
                    let response = "HTTP/1.1 400 Bad Request\r\nContent-Length: 0\r\n\r\n"
                    connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                        connection.cancel()
                        print("Failed to parse body for POST /note")
                    }))
                    return
                }
                
                noteModel.addNote(note)
                
                let response = "HTTP/1.1 201 Created\r\nContent-Length: 0\r\n\r\n"
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                    connection.cancel()
                    print("Successfully handled POST /note and added new note")
                }))
                
            } else if method == "GET" {
                let notes = noteModel.getNotes()
                if let data = try? JSONSerialization.data(withJSONObject: notes, options: .prettyPrinted) {
                    let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(data.count)\r\n\r\n"
                    connection.send(content: response.data(using: .utf8)! + data, completion: .contentProcessed({ _ in
                        connection.cancel()
                        print("Successfully handled GET /note and returned notes")
                    }))
                } else {
                    let response = "HTTP/1.1 500 Internal Server Error\r\nContent-Length: 0\r\n\r\n"
                    connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                        connection.cancel()
                        print("Failed to serialize notes for GET /note")
                    }))
                }
            } else {
                let response = "HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\n\r\n"
                connection.send(content: response.data(using: .utf8), completion: .contentProcessed({ _ in
                    connection.cancel()
                    print("Method not allowed for /note")
                }))
            }
        }
    }
}

