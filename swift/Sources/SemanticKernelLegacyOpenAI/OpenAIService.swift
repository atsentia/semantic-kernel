import SemanticKernelCore

/// Placeholder for OpenAI connector implementations.
public struct OpenAIService: TextCompletionService, ChatCompletionService, EmbeddingsService {
    public init() {}

    public func complete(prompt: String) async throws -> String {
        // TODO: implement OpenAI API call
        return ""
    }

    public func send(messages: [String]) async throws -> String {
        // TODO: implement OpenAI chat API call
        return ""
    }

    public func embeddings(for text: String) async throws -> [Float] {
        // TODO: implement OpenAI embeddings API call
        return []
    }
}
