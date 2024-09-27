import Foundation

class NoteController {
    let model = NoteModel()
    let webFramework: TinyWebFrameworkProtocol
    
    init(webFramework: TinyWebFrameworkProtocol) {
        self.webFramework = webFramework
    }
    
    func getNotes(request: HTTPRequest, respond: @escaping (HTTPResponse) -> Void) {
        let notes = model.getAllNotes()
        webFramework.jsonResponse(statusCode: 200, object: notes, responseHandler: respond)
    }

    func addNote(request: HTTPRequest, respond: @escaping (HTTPResponse) -> Void) {
        if let formData = webFramework.parseFormData(from: request.body),
           let title = formData["title"],
           let content = formData["content"] {
            let newNote = model.addNote(title: title, content: content)
            webFramework.jsonResponse(statusCode: 201, object: newNote, responseHandler: respond)
        } else {
            webFramework.errorResponse(statusCode: 400, message: "Invalid form data.", responseHandler: respond)
        }
    }

    func deleteNote(request: HTTPRequest, id: String, respond: @escaping (HTTPResponse) -> Void) {
        if model.deleteNoteByID(id) {
            let response = HTTPResponse(statusCode: 200, headers: ["Content-Type": "text/plain"], body: "Note deleted.".data(using: .utf8) ?? Data())
            respond(response)
        } else {
            webFramework.errorResponse(statusCode: 404, message: "Note not found.", responseHandler: respond)
        }
    }
}
