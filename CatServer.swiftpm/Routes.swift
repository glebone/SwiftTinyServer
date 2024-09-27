import Foundation

// Declare a global instance of NoteModel
let model = NoteModel()

// Setup all routes
func setupRoutes(webFramework: TinyWebFrameworkProtocol) {
    rootRoute(webFramework: webFramework)
    notesJSONRoute(webFramework: webFramework)
    notesHTMLRoute(webFramework: webFramework)
    noteIDRoute(webFramework: webFramework)
}

// Root route ("/")
func rootRoute(webFramework: TinyWebFrameworkProtocol) {
    webFramework.addRoute("/") { request, respond in
        let response = HTTPResponse(
            statusCode: 200,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: "<h1>Hello, World!</h1>".data(using: .utf8) ?? Data()
        )
        respond(response)
        print("Handled / route with Hello, World!")
    }
}

// GET /notes.json - Fetch all notes, POST /notes.json - Add a new note
func notesJSONRoute(webFramework: TinyWebFrameworkProtocol) {
    webFramework.addRoute("/notes.json") { request, responseHandler in
        if request.method == "GET" {
            let notes = model.getAllNotes()
            webFramework.jsonResponse(statusCode: 200, object: notes, responseHandler: responseHandler)
        } else if request.method == "POST" {
            let contentType = request.headers["Content-Type"] ?? ""
            
            if contentType.contains("application/x-www-form-urlencoded") {
                guard let formData = webFramework.parseFormData(from: request.body),
                      let title = formData["title"],
                      let content = formData["content"] else {
                    webFramework.errorResponse(statusCode: 400, message: "Invalid form data.", responseHandler: responseHandler)
                    return
                }
                let newNote = model.addNote(title: title, content: content)
                webFramework.jsonResponse(statusCode: 201, object: newNote, responseHandler: responseHandler)
            } else if contentType.contains("application/json") {
                guard let bodyString = String(data: request.body, encoding: .utf8),
                      let jsonData = bodyString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: String],
                      let title = json["title"],
                      let content = json["content"] else {
                    webFramework.errorResponse(statusCode: 400, message: "Invalid JSON request body.", responseHandler: responseHandler)
                    return
                }
                let newNote = model.addNote(title: title, content: content)
                webFramework.jsonResponse(statusCode: 201, object: newNote, responseHandler: responseHandler)
            } else {
                webFramework.errorResponse(statusCode: 415, message: "Unsupported media type.", responseHandler: responseHandler)
            }
        } else {
            webFramework.errorResponse(statusCode: 405, message: "Method not allowed.", responseHandler: responseHandler)
        }
    }
}

// GET /notes.html - Fetch all notes as an HTML page
func notesHTMLRoute(webFramework: TinyWebFrameworkProtocol) {
    webFramework.addRoute("/notes.html") { request, responseHandler in
        if request.method == "GET" {
            let notes = model.getAllNotes()
            do {
                let htmlTemplate = try webFramework.loadHTMLTemplate(named: "notes.html")
                let notesHTML = model.generateNotesHTML(from: notes)
                let htmlContent = htmlTemplate.replacingOccurrences(of: "{{notes}}", with: notesHTML)
                
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
}

// DELETE and GET /note/{id} - Fetch or delete a specific note by ID
func noteIDRoute(webFramework: TinyWebFrameworkProtocol) {
    webFramework.addRoute("/note/{id}") { request, responseHandler in
        print("Received request for /note/{id} with method: \(request.method)")
        
        let fullPath = request.path
        let pathComponents = fullPath.split(separator: "?")
        let id = pathComponents.first?.replacingOccurrences(of: "/note/", with: "") ?? ""
        
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
        
        let method = queryParams["_method"]?.uppercased() ?? request.method.uppercased()
        
        if method == "DELETE" {
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
        
        guard let note = model.getNoteByID(id) else {
            webFramework.errorResponse(statusCode: 404, message: "Note not found for read.", responseHandler: responseHandler)
            return
        }
        
        webFramework.jsonResponse(statusCode: 200, object: note, responseHandler: responseHandler)
    }
}
