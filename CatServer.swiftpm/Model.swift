import Foundation

class Model {
    func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getBundlePath(for fileName: String) -> URL? {
        return Bundle.main.url(forResource: fileName, withExtension: nil)
    }
    
    func readJSONFile(named fileName: String) -> [[String: String]] {
        let fileURL: URL
        let documentsURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: documentsURL.path) {
            fileURL = documentsURL
        } else if let bundleURL = getBundlePath(for: fileName) {
            fileURL = bundleURL
        } else {
            print("Failed to locate \(fileName) in both documents directory and bundle")
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
        let fileURL = getDocumentsDirectory().appendingPathComponent(fileName)
        do {
            let data = try JSONSerialization.data(withJSONObject: content, options: .prettyPrinted)
            try data.write(to: fileURL, options: .atomic)
            print("Successfully wrote JSON to \(fileName) in documents directory")
        } catch {
            print("Failed to write JSON file \(fileName): \(error)")
        }
    }
}
