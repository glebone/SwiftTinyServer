import Foundation

// Declare a global instance of NoteModel
let model = NoteModel()

// Define routes
func setupRoutes(webFramework: TinyWebFrameworkProtocol) {
    
    // Root route ("/")
    webFramework.addRoute("/") { request, respond in
        let response = HTTPResponse(
            statusCode: 200,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: "<h1>Hello, World!</h1>".data(using: .utf8) ?? Data()
        )
        respond(response)
        print("Handled / route with Hello, World!")
    }
    
    // GET /notes - Fetch all notes, POST /notes - Add a new note
    webFramework.addRoute("/notes") { request, responseHandler in
        if request.method == "GET" {
            // Handle GET request to fetch all notes
            let notes = model.getAllNotes()
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            do {
                let data = try encoder.encode(notes)
                let response = HTTPResponse(
                    statusCode: 200,
                    headers: ["Content-Type": "application/json"],
                    body: data
                )
                responseHandler(response)
            } catch {
                let response = HTTPResponse(
                    statusCode: 500,
                    headers: ["Content-Type": "text/plain"],
                    body: "Error encoding notes.".data(using: .utf8) ?? Data()
                )
                responseHandler(response)
            }
        } else if request.method == "POST" {
            // Handle POST request to add a new note
            guard let bodyString = String(data: request.body, encoding: .utf8),
                  let jsonData = bodyString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String],
                  let title = json["title"], let content = json["content"] else {
                let response = HTTPResponse(
                    statusCode: 400,
                    headers: ["Content-Type": "text/plain"],
                    body: "Invalid request body.".data(using: .utf8) ?? Data()
                )
                responseHandler(response)
                return
            }
            
            let newNote = model.addNote(title: title, content: content)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            
            do {
                let data = try encoder.encode(newNote)
                let response = HTTPResponse(
                    statusCode: 201,
                    headers: ["Content-Type": "application/json"],
                    body: data
                )
                responseHandler(response)
            } catch {
                let response = HTTPResponse(
                    statusCode: 500,
                    headers: ["Content-Type": "text/plain"],
                    body: "Error encoding new note.".data(using: .utf8) ?? Data()
                )
                responseHandler(response)
            }
        } else {
            // Handle unsupported HTTP method
            let response = HTTPResponse(
                statusCode: 405,
                headers: ["Content-Type": "text/plain"],
                body: "Method not allowed.".data(using: .utf8) ?? Data()
            )
            responseHandler(response)
        }
    }
    
    // GET /note/{id} - Fetch a specific note by ID
    // GET /note/{id} - Fetch a specific note by ID
    // Root route ("/")
    webFramework.addRoute("/note") { request, respond in
        print("Received request for path: \(request.path)") // Debug: Print the full path
        if request.path.starts(with: "/note/") {
            // Extract the ID part from the path (e.g., /note/D96E3D8F-91F3-4F8E-BD89-1ABFD8D3A123 -> D96E3D8F-91F3-4F8E-BD89-1ABFD8D3A123)
            let id = request.path.replacingOccurrences(of: "/note/", with: "")
            print("Extracted ID: \(id)") // Debug: Print the extracted ID
        }
        let response = HTTPResponse(
            statusCode: 200,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: "<h1>Hello, Notes!</h1>".data(using: .utf8) ?? Data()
        )
        respond(response)
        print("Handled /note route with Hello, NOte!")
    }
    webFramework.addRoute("/note/{id}") { request, respond in
        print("Received request for /note/{id}") // Debug: Print the request path
        
        // Extract the {id} from the path
        let id = request.path.replacingOccurrences(of: "/note/", with: "")
        print("Extracted ID: \(id)") // Debug: Print the extracted ID
        
        // Fetch the note by ID
        guard let note = model.getNoteByID(id) else {
            // If the note is not found, return a 404 response
            print("Note not found for ID: \(id)") // Debug
            let response = HTTPResponse(
                statusCode: 404,
                headers: ["Content-Type": "text/plain"],
                body: "Note not found.".data(using: .utf8) ?? Data()
            )
            respond(response)
            return
        }
        
        // Debug: Print the found note details
        print("Note found: \(note)")
        
        // Encode the note object into JSON format
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            // Convert the note to JSON data
            let data = try encoder.encode(note)
            print("Successfully encoded note to JSON: \(String(data: data, encoding: .utf8) ?? "")") // Debug
            
            // Return the JSON response with status 200 (OK)
            let response = HTTPResponse(
                statusCode: 200,
                headers: ["Content-Type": "application/json"],
                body: data
            )
            respond(response)
        } catch {
            // Handle JSON encoding errors
            print("Error encoding note to JSON: \(error)") // Debug
            let response = HTTPResponse(
                statusCode: 500,
                headers: ["Content-Type": "text/plain"],
                body: "Error encoding note.".data(using: .utf8) ?? Data()
            )
            respond(response)
        }
    }
    
}
public func startWebApp(with webFramework: TinyWebFrameworkProtocol) {
    setupRoutes(webFramework: webFramework)
    webFramework.startServer(host: "127.0.0.1", port: 8080)
}
