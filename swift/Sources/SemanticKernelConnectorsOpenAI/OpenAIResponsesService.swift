import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenAIResponsesService: Sendable {
    public struct MessageContent: Codable {
        let type: String
        let text: String
    }
    public struct Message: Codable {
        let role: String
        let content: [MessageContent]
    }
    public struct TextFormat: Codable { let type: String }
    public struct Text: Codable { let format: TextFormat }
    public struct Reasoning: Codable { let effort: String; let summary: String }
    public struct Tool: Codable { let type: String }
    public struct RequestBody: Codable {
        let model: String
        let input: [Message]
        let text: Text
        let reasoning: Reasoning
        let tools: [Tool]
        let store: Bool
    }

    private let apiKey: String
    private let session: URLSession
    private let baseURL: URL

    public init(apiKey: String? = nil, baseURL: URL? = nil, session: URLSession = .shared) {
        self.apiKey = apiKey ?? Environment.apiKey ?? ""
        self.baseURL = baseURL ?? URL(string: "https://api.openai.com")!
        self.session = session
    }

    public func response(for topic: String) async throws -> Data {
        let url = baseURL.appendingPathComponent("v1/responses")
        let body = RequestBody(
            model: "gpt-4o-mini",
            input: [
                Message(
                    role: "developer",
                    content: [
                        MessageContent(
                            type: "input_text",
                            text: """
                            You are a research assistant. Read the user's topic and return a concise summary of recent and reliable information. Include sources when relevant.
                            """
                        )
                    ]
                ),
                Message(role: "user", content: [MessageContent(type: "input_text", text: "Can you help me research \(topic) and summarize the latest findings?")])
            ],
            text: Text(format: TextFormat(type: "text")),
            reasoning: Reasoning(effort: "medium", summary: "auto"),
            tools: [Tool(type: "web_search_preview")],
            store: true
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.badServerResponse, userInfo: ["status": status])
        }
        return data
    }
}
