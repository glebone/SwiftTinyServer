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
    
    // GET /notes.json - Fetch all notes, POST /notes.json - Add a new note
    webFramework.addRoute("/notes.json") { request, responseHandler in
        if request.method == "GET" {
            // Handle GET request to fetch all notes
            let notes = model.getAllNotes()
            
            webFramework.jsonResponse(statusCode: 200, object: notes, responseHandler: responseHandler)
        } else if request.method == "POST" {
            // Handle POST request to add a new note
            let contentType = request.headers["Content-Type"] ?? ""
            
            if contentType.contains("application/x-www-form-urlencoded") {
                // Handle form submission (HTML form encoded data)
                guard let formData = webFramework.parseFormData(from: request.body),
                      let title = formData["title"],
                      let content = formData["content"] else {
                    webFramework.errorResponse(statusCode: 400, message: "Invalid form data.", responseHandler: responseHandler)
                    return
                }
                
                // Add the new note to the model
                let newNote = model.addNote(title: title, content: content)
                
                webFramework.jsonResponse(statusCode: 201, object: newNote, responseHandler: responseHandler)
            } else if contentType.contains("application/json") {
                // Handle JSON POST request (e.g., from curl)
                guard let bodyString = String(data: request.body, encoding: .utf8),
                      let jsonData = bodyString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String],
                      let title = json["title"],
                      let content = json["content"] else {
                    webFramework.errorResponse(statusCode: 400, message: "Invalid JSON request body.", responseHandler: responseHandler)
                    return
                }
                
                // Add the new note to the model
                let newNote = model.addNote(title: title, content: content)
                
                webFramework.jsonResponse(statusCode: 201, object: newNote, responseHandler: responseHandler)
            } else {
                webFramework.errorResponse(statusCode: 415, message: "Unsupported media type.", responseHandler: responseHandler)
            }
        } else {
            webFramework.errorResponse(statusCode: 405, message: "Method not allowed.", responseHandler: responseHandler)
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
                webFramework.errorResponse(statusCode: 500, message: "Error loading HTML template.", responseHandler: responseHandler)
            }
        } else {
            webFramework.errorResponse(statusCode: 405, message: "Method not allowed.", responseHandler: responseHandler)
        }
    }
    
    // DELETE and GET /note/{id} - Fetch or delete a specific note by ID
    webFramework.addRoute("/note/{id}") { request, responseHandler in
        print("Received request for /note/{id} with method: \(request.method)")
        
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
        print("Extracted ID: \(id)")
        print("Method requested: \(method)")
        print("--------------------")
        
        // Check if the request is a DELETE method or a POST with _method=DELETE
        if method == "DELETE" {
            print("Delete request for note with ID: \(id)")
            
            if model.deleteNoteByID(id) {
                let response = HTTPResponse(
                    statusCode: 200,
                    headers: ["Content-Type": "text/plain"],
                    body: "Note deleted successfully.".data(using: .utf8) ?? Data()
                )
                responseHandler(response)
            } else {
                webFramework.errorResponse(statusCode: 404, message: "Note not found for delete.", responseHandler: responseHandler)
            }
            return
        }
        
        // For non-DELETE methods, handle note retrieval
        guard let note = model.getNoteByID(id) else {
            webFramework.errorResponse(statusCode: 404, message: "Note not found for read.", responseHandler: responseHandler)
            return
        }
        
        webFramework.jsonResponse(statusCode: 200, object: note, responseHandler: responseHandler)
    }
}

// Start the web app
public func startWebApp(with webFramework: TinyWebFrameworkProtocol) {
    setupRoutes(webFramework: webFramework)
    webFramework.startServer(host: "127.0.0.1", port: 8080)
}
