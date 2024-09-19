// Model.swift
import Foundation

class Model {
    func getWorkingDirectory() -> URL {

#if os(macOS) || os(iOS)
        // Use the documents directory on iOS
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
#else
        // Use the current directory on Linux
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
#endif
    }
    
    func getBundlePath(for fileName: String) -> URL? {
        // Attempt to locate the file in the app's bundle
        return Bundle.main.url(forResource: fileName, withExtension: nil)
    }
    
    func readJSONFile(named fileName: String) -> [[String: String]] {
        let fileURL: URL
        let documentsURL = getWorkingDirectory().appendingPathComponent(fileName)
        
        // First, check if the file exists in the documents directory
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            fileURL = documentsURL
        } 
        // If not, check if the file exists in the bundle
        else if let bundleURL = getBundlePath(for: fileName) {
            fileURL = bundleURL
        } else {
            print("Failed to locate \(fileName) in both documents directory and bundle")
            return []
        }
        
        // Try reading the file from the determined fileURL
        do {
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]]
            print("Successfully read JSON from \(fileName): \(String(describing: json))")
            return json ?? []
        } catch {
            print("Failed to read JSON file \(fileName): \(error)")
            return []
        }
    }
    
    func writeJSONFile(named fileName: String, content: [[String: String]]) {
        let fileURL = getWorkingDirectory().appendingPathComponent(fileName)
        do {
            let data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
            try data.write(to: fileURL, options: .atomic)
            print("Successfully wrote JSON to \(fileName) in working directory")
        } catch {
            print("Failed to write JSON file \(fileName): \(error)")
        }
    }
}
