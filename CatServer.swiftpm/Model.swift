import Foundation

class Model {
    func getWorkingDirectory() -> URL {
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }

    func readJSONFile(named fileName: String) -> [[String: String]] {
        let fileURL = getWorkingDirectory().appendingPathComponent(fileName)

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            print("File \(fileName) does not exist at path \(fileURL.path)")
            return []
        }

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
