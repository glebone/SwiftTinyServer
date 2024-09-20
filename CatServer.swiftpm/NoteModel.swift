import Foundation

// NoteModel.swift

struct Note: Codable {
    var id: String     // Unique ID for each note
    var title: String
    var content: String
    var date: String
}

// NoteModel to manage a list of notes
import Foundation

class NoteModel: Model {
    private let fileName = "notes.json"
    private var notes: [Note] = [] // In-memory array of notes
    
    override init() {
        super.init()
        // Load notes from the JSON file on initialization
        notes = loadNotesFromFile()
    }
    
    // Add a new note and save it to the file
    func addNote(title: String, content: String) -> Note {
        let newNote = Note(id: UUID().uuidString, title: title, content: content, date: getCurrentDate())
        notes.append(newNote)
        saveNotesToFile()
        return newNote
    }
    
    // Get all notes
    func getAllNotes() -> [Note] {
        return notes
    }
    
    // Get a note by UDID
    func getNoteByID(_ id: String) -> Note? {
        return notes.first { $0.id == id }
    }
    
    // Load notes from JSON file
    private func loadNotesFromFile() -> [Note] {
        // Read the raw JSON data from the file
        let jsonArray = readJSONFile(named: fileName)
        
        // You need to first convert this JSON array back to Data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Create Data directly from the JSON array string
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
            let notesArray = try decoder.decode([Note].self, from: jsonData)
            print("Successfully loaded notes from file.")
            return notesArray
        } catch {
            print("Failed to load notes from file: \(error)")
            return []
        }
    }
    
    // Save notes to JSON file
    private func saveNotesToFile() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            // Encode the array of notes directly to JSON Data
            let data = try encoder.encode(notes)
            
            // Write the raw Data directly to the JSON file
            let fileURL = getWorkingDirectory().appendingPathComponent(fileName)
            try data.write(to: fileURL)
            
            print("Successfully saved notes to file.")
        } catch {
            print("Failed to save notes: \(error)")
        }
    }
    
    // Helper method to get the current date in ISO 8601 format
    private func getCurrentDate() -> String {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.string(from: Date())
    }
}
