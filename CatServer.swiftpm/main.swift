import NIO
import NIOHTTP1
import Foundation

#if os(Linux)
func linuxLaunch() {
    let webFramework = TinyWebFramework()
    let noteModel = NoteModel()

    webFramework.addRoute("/") { context, request in
        let headers = HTTPHeaders([("content-type", "text/html; charset=utf-8")])
        let responseHead = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
        context.write(NIOAny(HTTPServerResponsePart.head(responseHead)), promise: nil)

        var buffer = context.channel.allocator.buffer(capacity: 128)
        buffer.writeString("<h1>Hello, World!</h1>")
        context.write(NIOAny(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)

        context.writeAndFlush(NIOAny(HTTPServerResponsePart.end(nil))).whenComplete { _ in
            context.close(promise: nil)
            print("Handled / route with Hello, World!")
        }
    }

    webFramework.addRoute("/note") { context, request in
        let method = request.head.method.rawValue
        print("Handling /note route with method: \(method)")

        if method == "POST" {
            // Handle POST
            if let noteDict = try? JSONSerialization.jsonObject(with: request.body, options: []) as? [String: String] {
                noteModel.addNote(noteDict)

                let headers = HTTPHeaders([("content-length", "0")])
                let responseHead = HTTPResponseHead(version: .http1_1, status: .created, headers: headers)
                context.writeAndFlush(NIOAny(HTTPServerResponsePart.head(responseHead))).whenComplete { _ in
                    context.close(promise: nil)
                    print("Successfully handled POST /note and added new note")
                }
            } else {
                let headers = HTTPHeaders([("content-length", "0")])
                let responseHead = HTTPResponseHead(version: .http1_1, status: .badRequest, headers: headers)
                context.writeAndFlush(NIOAny(HTTPServerResponsePart.head(responseHead))).whenComplete { _ in
                    context.close(promise: nil)
                    print("Failed to parse body for POST /note")
                }
            }
        } else if method == "GET" {
            let notes = noteModel.getNotes()
            if let data = try? JSONSerialization.data(withJSONObject: notes, options: []) {
                let headers = HTTPHeaders([
                    ("content-type", "application/json"),
                    ("content-length", "\(data.count)")
                ])
                let responseHead = HTTPResponseHead(version: .http1_1, status: .ok, headers: headers)
                context.write(NIOAny(HTTPServerResponsePart.head(responseHead)), promise: nil)

                var buffer = context.channel.allocator.buffer(capacity: data.count)
                buffer.writeBytes(data)
                context.write(NIOAny(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)

                context.writeAndFlush(NIOAny(HTTPServerResponsePart.end(nil))).whenComplete { _ in
                    context.close(promise: nil)
                    print("Successfully handled GET /note and returned notes")
                }
            } else {
                let headers = HTTPHeaders([("content-length", "0")])
                let responseHead = HTTPResponseHead(version: .http1_1, status: .internalServerError, headers: headers)
                context.writeAndFlush(NIOAny(HTTPServerResponsePart.head(responseHead))).whenComplete { _ in
                    context.close(promise: nil)
                    print("Failed to serialize notes for GET /note")
                }
            }
        } else {
            let headers = HTTPHeaders([("content-length", "0")])
            let responseHead = HTTPResponseHead(version: .http1_1, status: .methodNotAllowed, headers: headers)
            context.writeAndFlush(NIOAny(HTTPServerResponsePart.head(responseHead))).whenComplete { _ in
                context.close(promise: nil)
                print("Method not allowed for /note")
            }
        }
    }

    webFramework.startServer()

    // Keep the server running indefinitely
    do {
        try webFramework.channel?.closeFuture.wait()
    } catch {
        print("Server closed with error: \(error)")
    }
}

linuxLaunch()
#endif
