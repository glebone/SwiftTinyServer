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
   
    // GET /notes.json - Fetch all notes as JSON, POST /notes.json - Add a new note
    webFramework.addRoute("/notes.json") { request, responseHandler in
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
            let contentType = request.headers["Content-Type"] ?? ""
            
            if contentType.contains("application/x-www-form-urlencoded") {
                // Handle form submission (HTML form encoded data)
                guard let bodyString = String(data: request.body, encoding: .utf8) else {
                    let response = HTTPResponse(
                        statusCode: 400,
                        headers: ["Content-Type": "text/plain"],
                        body: "Invalid request body.".data(using: .utf8) ?? Data()
                    )
                    responseHandler(response)
                    return
                }
                
                // Parse form-encoded data
                let formData = bodyString.split(separator: "&").reduce(into: [String: String]()) { result, keyValuePair in
                    let pair = keyValuePair.split(separator: "=")
                    if pair.count == 2, let key = pair.first?.removingPercentEncoding, let value = pair.last?.removingPercentEncoding {
                        result[key] = value
                    }
                }
                
                guard let title = formData["title"], let content = formData["content"] else {
                    let response = HTTPResponse(
                        statusCode: 400,
                        headers: ["Content-Type": "text/plain"],
                        body: "Invalid form data.".data(using: .utf8) ?? Data()
                    )
                    responseHandler(response)
                    return
                }
                
                // Add the new note to the model
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
            } else if contentType.contains("application/json") {
                // Handle JSON POST request (e.g., from curl)
                guard let bodyString = String(data: request.body, encoding: .utf8),
                      let jsonData = bodyString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String],
                      let title = json["title"], let content = json["content"] else {
                    let response = HTTPResponse(
                        statusCode: 400,
                        headers: ["Content-Type": "text/plain"],
                        body: "Invalid JSON request body.".data(using: .utf8) ?? Data()
                    )
                    responseHandler(response)
                    return
                }

                // Add the new note to the model
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
                // Unsupported content type
                let response = HTTPResponse(
                    statusCode: 415,
                    headers: ["Content-Type": "text/plain"],
                    body: "Unsupported media type.".data(using: .utf8) ?? Data()
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
    
    
    // GET /notes.html - Fetch all notes as an HTML page
       webFramework.addRoute("/notes.html") { request, responseHandler in
           if request.method == "GET" {
               let notes = model.getAllNotes()
               
               do {
                   // Load the HTML template
                   let htmlTemplate = try webFramework.loadHTMLTemplate(named: "notes.html")
                   
                   // Generate the HTML content from the notes
                   let notesHTML = model.generateNotesHTML(from: notes)
                   
                   // Replace the placeholder in the HTML template with the actual notes
                   let htmlContent = htmlTemplate.replacingOccurrences(of: "{{notes}}", with: notesHTML)
                   
                   // Respond with the HTML content
                   let response = HTTPResponse(
                       statusCode: 200,
                       headers: ["Content-Type": "text/html"],
                       body: htmlContent.data(using: .utf8) ?? Data()
                   )
                   responseHandler(response)
               } catch {
                   let response = HTTPResponse(
                       statusCode: 500,
                       headers: ["Content-Type": "text/plain"],
                       body: "Error loading HTML template.".data(using: .utf8) ?? Data()
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
    
    
    webFramework.addRoute("/note/{id}") { request, responseHandler in
        print("Received request for /note/{id}") // Debug: Print the request path
        print("With method: \(request.method)")

        // Extract the {id} from the path, without query parameters
        let fullPath = request.path
        let pathComponents = fullPath.split(separator: "?")
        let id = pathComponents.first?.replacingOccurrences(of: "/note/", with: "") ?? ""

        // Parse the query string if present (e.g., ?_method=DELETE)
        var queryParams: [String: String] = [:]
        if pathComponents.count > 1 {
            let queryString = String(pathComponents[1])
            queryParams = queryString.split(separator: "&").reduce(into: [:]) { result, queryItem in
                let parts = queryItem.split(separator: "=")
                if parts.count == 2 {
                    result[String(parts[0])] = String(parts[1])
                }
            }
        }

        // Check if _method=DELETE is present in the query parameters
        let method = queryParams["_method"]?.uppercased() ?? request.method.uppercased()

        print("--------------------")
        print("Extracted ID: \(id)") // Debug: Print the extracted ID
        print("Method requested: \(method)")
        print("--------------------")

        // Check if the request is a DELETE method or a POST with _method=DELETE
        if method == "DELETE" {
            // Handle DELETE request to remove a note
            print("Delete request for note with ID: \(id)")

            if model.deleteNoteByID(id) {
                let response = HTTPResponse(
                    statusCode: 200,
                    headers: ["Content-Type": "text/plain"],
                    body: "Note deleted successfully.".data(using: .utf8) ?? Data()
                )
                responseHandler(response)
            } else {
                let response = HTTPResponse(
                    statusCode: 404,
                    headers: ["Content-Type": "text/plain"],
                    body: "Note not found for delete.".data(using: .utf8) ?? Data()
                )
                responseHandler(response)
            }
            return
        }
        
        // For non-DELETE methods, handle note retrieval
        guard let note = model.getNoteByID(id) else {
            let response = HTTPResponse(
                statusCode: 404,
                headers: ["Content-Type": "text/plain"],
                body: "Note not found for read.".data(using: .utf8) ?? Data()
            )
            responseHandler(response)
            return
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(note)
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
                body: "Error encoding note.".data(using: .utf8) ?? Data()
            )
            responseHandler(response)
        }
    }
    
}
public func startWebApp(with webFramework: TinyWebFrameworkProtocol) {
    setupRoutes(webFramework: webFramework)
    webFramework.startServer(host: "127.0.0.1", port: 8080)
}
