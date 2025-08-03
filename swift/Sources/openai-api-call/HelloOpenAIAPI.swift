import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Entry point

@main
struct HelloOpenAIAPI {
    static func main() async {
        let topic = CommandLine.arguments.dropFirst().first ?? "quantum computing"
        do {
            let data = try await openAIResponse(for: topic)
            print(data)
        } catch {
            print("Error:", error)
        }
    }
}

enum EnvError: Error {
    case missingKey
}

/// Loads the `OPENAI_API_KEY` from the current environment or a local `.env` file.
func loadAPIKey() throws -> String {
    // 1. Try explicit environment variable first (works if `.env` already sourced).
    if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
        return key
    }
    
    // 2. Fallback: parse local `.env` file.
    let path = ".env"
    guard
        FileManager.default.fileExists(atPath: path),
        let data = FileManager.default.contents(atPath: path),
        let content = String(data: data, encoding: .utf8)
    else {
        throw EnvError.missingKey
    }
    
    for line in content.split(whereSeparator: \.isNewline) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard
            !trimmed.hasPrefix("#"),
            let equalIndex = trimmed.firstIndex(of: "=")
        else { continue }
        
        let key = trimmed[..<equalIndex].trimmingCharacters(in: .whitespaces)
        let rawValue = trimmed[trimmed.index(after: equalIndex)...].trimmingCharacters(in: .whitespaces)
        // Strip surrounding quotes if present
        let value = rawValue.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        if key == "OPENAI_API_KEY" {
            return value
        }
    }
    
    throw EnvError.missingKey
}

// MARK: - Request payload types

struct MessageContent: Codable {
    let type: String
    let text: String
}

struct Message: Codable {
    let role: String
    let content: [MessageContent]
}

struct TextFormat: Codable {
    let type: String
}

struct Text: Codable {
    let format: TextFormat
}


struct Tool: Codable {
    let type: String
}

struct RequestBody: Codable {
    let model: String
    let input: [Message]
    let text: Text
    let reasoning: [String: String]
    let tools: [Tool]
    let temperature: Double
    let max_output_tokens: Int
    let top_p: Double
    let store: Bool
}

// MARK: - OpenAI API call

/// Sends the request and returns the raw response data.
func openAIResponse(for topic: String) async throws -> Data {
    let apiKey = try loadAPIKey()
    let url = URL(string: "https://api.openai.com/v1/responses")!
    
    let body = RequestBody(
        model: "gpt-4.1-mini",
        input: [
            Message(
                role: "system",
                content: [
                    .init(
                        type: "input_text",
                        text: "You are a research assistant. Read the user's topic and return a concise summary of recent and reliable information. Include sources when relevant."
                    )
                ]
            ),
            Message(
                role: "user",
                content: [
                    .init(
                        type: "input_text",
                        text: "Can you help me research \(topic) and summarize the latest findings?"
                    )
                ]
            )
        ],
        text: Text(format: TextFormat(type: "text")),
        reasoning: [:],
        tools: [Tool(type: "web_search_preview")],
        temperature: 1,
        max_output_tokens: 2048,
        top_p: 1,
        store: true
    )
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1
        throw URLError(.badServerResponse, userInfo: ["status": status])
    }
    
    return data
}

