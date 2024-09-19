// NoteModel.swift
import Foundation

class NoteModel: Model {
    private let fileName = "notes.json"
    
    func addNote(_ note: [String: String]) {
        var notes = readJSONFile(named: fileName)
        var newNote = note
        addDateToNote(&newNote)
        notes.append(newNote)
        writeJSONFile(named: fileName, content: notes)
    }
    
    func getNotes() -> [[String: String]] {
        return readJSONFile(named: fileName)
    }
    
    private func addDateToNote(_ note: inout [String: String]) {
        let dateFormatter = ISO8601DateFormatter()
        note["date"] = dateFormatter.string(from: Date())
        print("Added date to note: \(note)")
    }
}
