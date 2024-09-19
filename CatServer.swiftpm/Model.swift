// Model.swift
import Foundation

class Model {
    

    func getWorkingDirectory() -> URL {
        #if os(macOS) || os(iOS)
            // Use the documents directory on iOS/macOS
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let directory = paths.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            print("getWorkingDirectory() on iOS/macOS returns: \(directory.path)")
            return directory
        #else
            // Use the current directory on Linux
            let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            print("getWorkingDirectory() on Linux returns: \(directory.path)")
            return directory
        #endif
    }
    
    func getBundlePath(for fileName: String) -> URL? {
        // Attempt to locate the file in the app's bundle
        return Bundle.main.url(forResource: fileName, withExtension: nil)
    }
    
    func readJSONFile(named fileName: String) -> [[String: String]] {
        let fileURL: URL
        let documentsURL: URL

        // Debugging the working directory
        let workingDirectory = getWorkingDirectory()
        print("Working directory: \(workingDirectory.path)")

        #if os(macOS) || os(iOS)
            // Use documents directory on iOS/macOS
            documentsURL = workingDirectory.appendingPathComponent(fileName)
        #else
            // Use the Resources directory on Linux
            documentsURL = workingDirectory.appendingPathComponent("Resources").appendingPathComponent(fileName)
        #endif

        print("Attempting to read JSON file \(fileName)")
        print("Constructed path: \(documentsURL.path)")

        // Check if the file exists at the constructed path
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            fileURL = documentsURL
        }
        // If not, check if the file exists in the bundle (unlikely on Linux)
        else if let bundleURL = getBundlePath(for: fileName) {
            fileURL = bundleURL
        } else {
            print("Failed to locate \(fileName) in both documents directory and bundle")
            return []
        }

        // Proceed to read the file
        do {
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: String]]
            return json ?? []
        } catch {
            print("Error reading JSON file: \(error)")
            return []
        }
    }
    

    func writeJSONFile(named fileName: String, content: [[String: String]]) {
        let fileURL: URL
        let documentsURL: URL

        // Debugging the working directory
        let workingDirectory = getWorkingDirectory()
        print("Working directory: \(workingDirectory.path)")

        #if os(macOS) || os(iOS)
            // Use documents directory on iOS/macOS
            documentsURL = workingDirectory.appendingPathComponent(fileName)
        #else
            // Use the Resources directory on Linux
            documentsURL = workingDirectory.appendingPathComponent("Resources").appendingPathComponent(fileName)
        #endif

        print("Attempting to write JSON file \(fileName)")
        print("Constructed path: \(documentsURL.path)")

        // Ensure the Resources directory exists on Linux
        #if !os(macOS) && !os(iOS)
        let resourcesURL = workingDirectory.appendingPathComponent("Resources")
        if !FileManager.default.fileExists(atPath: resourcesURL.path) {
            do {
                try FileManager.default.createDirectory(at: resourcesURL, withIntermediateDirectories: true, attributes: nil)
                print("Created Resources directory at \(resourcesURL.path)")
            } catch {
                print("Failed to create Resources directory: \(error)")
                return
            }
        }
        #endif

        // Proceed to write the file
        do {
            let data = try JSONSerialization.data(withJSONObject: content, options: [.prettyPrinted])
            try data.write(to: documentsURL)
            print("Successfully wrote JSON file to \(documentsURL.path)")
        } catch {
            print("Error writing JSON file: \(error)")
        }
    }


}
