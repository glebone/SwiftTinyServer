// webapp.swift
import Foundation

// Define the web application setup
func setupRoutes(for webFramework: TinyWebFrameworkProtocol) {
    let noteModel = NoteModel()
    
    webFramework.addRoute("/") { request, respond in
        let response = HTTPResponse(
            statusCode: 200,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: "<h1>Hello, World!</h1>".data(using: .utf8) ?? Data()
        )
        respond(response)
        print("Handled / route with Hello, World!")
    }
    
    
    webFramework.addRoute("/note") { request, respond in
        let method = request.method
        print("Handling /note route with method: \(method)")
        if method == "POST" {
            
            if let bodyString = String(data: request.body, encoding: .utf8) {
                print("Request body as string: \(bodyString)")
            } else {
                print("Failed to decode request body as string.")
            }
            
            
            if let noteDict = try? JSONSerialization.jsonObject(with: request.body, options: []) as? [String: String] {
                noteModel.addNote(noteDict)
                let response = HTTPResponse(statusCode: 201, headers: [:], body: Data())
                respond(response)
                print("Successfully handled POST /note and added new note")
            } else {
                let response = HTTPResponse(statusCode: 400, headers: [:], body: Data())
                respond(response)
                print("Failed to parse body for POST /note")
            }
        }
        else
        {
            let response = HTTPResponse(statusCode: 405, headers: [:], body: Data())
            respond(response)
            print("Method not allowed for /note right now")
        }
    }
                            
    
    
    webFramework.addRoute("/notes") { request, respond in
        let method = request.method
        print("Handling /notes route with method: \(method)")
        
        if method == "POST" {
            let response = HTTPResponse(statusCode: 405, headers: [:], body: Data())
            respond(response)
            print("Method not allowed for /notes right now")
                        
        } else if method == "GET" {
            let notes = noteModel.getNotes()
            if let data = try? JSONSerialization.data(withJSONObject: notes, options: []) {
                let response = HTTPResponse(
                    statusCode: 200,
                    headers: ["Content-Type": "application/json"],
                    body: data
                )
                respond(response)
                print("Successfully handled GET /note and returned notes")
            } else {
                let response = HTTPResponse(statusCode: 500, headers: [:], body: Data())
                respond(response)
                print("Failed to serialize notes for GET /note")
            }
        } else {
            let response = HTTPResponse(statusCode: 405, headers: [:], body: Data())
            respond(response)
            print("Method not allowed for /note")
        }
    }
}

public func startWebApp(with webFramework: TinyWebFrameworkProtocol) {
    setupRoutes(for: webFramework)
    webFramework.startServer(host: "127.0.0.1", port: 8080)
}
