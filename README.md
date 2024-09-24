# TinyWebFramework

TinyWebFramework is a lightweight, multiplatform web framework designed to run on iPadOS, macOS, and Linux. This framework provides basic HTTP handling, including routing and simple model management. It allows you to easily create and manage routes for basic web applications, supporting multiple platforms with a unified API.

## Features

- **Multiplatform**: Runs on iPadOS (via Swift Playgrounds), macOS, and Linux.
- **Routing**: Define routes for HTTP requests (e.g., `GET`, `POST`).
- **JSON Support**: Handle JSON payloads in requests and responses.
- **Lightweight**: Designed to be small and easy to use for quick development.

## How to Use

1. **Run the Server**:
   - On **iPadOS** or **macOS**, simply run the project in Swift Playgrounds or Xcode.
   - On **Linux**, compile and run the Swift package using `swift build` and `swift run`.

2. **Test the POST `/note` Endpoint**:

   Use the following `curl` command to test the POST request on the `/note` endpoint:

   ```bash
   curl -X POST http://127.0.0.1:8080/notes.json \
   -H "Content-Type: application/json" \
   -d '{
       "title": "Test Note",
       "content": "Some Text for the test note"
   }'
   
   For the get some note 
   
curl -X GET http://127.0.0.1:8080/note/D96E3D8F-91F3-4F8E-BD89-1ABFD8D3A123