import Foundation

/// Extended chat completion service that supports function calling
public protocol FunctionAwareChatCompletionService: ChatCompletionService {
    func generateMessage(history: [ChatMessage], settings: CompletionSettings?, functions: [FunctionDefinition]?) async throws -> ChatMessage
}