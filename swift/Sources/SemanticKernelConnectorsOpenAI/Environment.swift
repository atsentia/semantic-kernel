import Foundation

public enum Environment {
    public static var apiKey: String? {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            return key
        }
        
        // Fallback to .env file if present - try multiple locations
        let possiblePaths = [
            ".env",  // Current directory
            Bundle.main.path(forResource: ".env", ofType: nil),  // App bundle
            "/Users/amund/SwiftSemanticKernel/swift/.env",  // Project root (for simulator)
        ].compactMap { $0 }
        
        for path in possiblePaths {
            guard
                FileManager.default.fileExists(atPath: path),
                let data = FileManager.default.contents(atPath: path),
                let content = String(data: data, encoding: .utf8)
            else { continue }
            
            for line in content.split(whereSeparator: \.isNewline) {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.hasPrefix("#"), let idx = trimmed.firstIndex(of: "=") else { continue }
                let keyPart = trimmed[..<idx].trimmingCharacters(in: .whitespaces)
                let rawValue = trimmed[trimmed.index(after: idx)...].trimmingCharacters(in: .whitespaces)
                let value = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                if keyPart == "OPENAI_API_KEY" {
                    return value
                }
            }
        }
        return nil
    }
    static var baseURL: URL? {
        if let str = ProcessInfo.processInfo.environment["OPENAI_BASE_URL"] {
            return URL(string: str)
        }
        return nil
    }
    static var apiVersion: String? {
        ProcessInfo.processInfo.environment["OPENAI_API_VERSION"]
    }
}
