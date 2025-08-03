import Foundation

public protocol ChatCompletionService: Sendable {
    func generateMessage(history: [ChatMessage], settings: CompletionSettings?) async throws -> ChatMessage
    func streamMessages(history: [ChatMessage], settings: CompletionSettings?) -> AsyncThrowingStream<ChatMessage, Error>
}

public extension ChatCompletionService {
    func streamMessages(history: [ChatMessage], settings: CompletionSettings?) -> AsyncThrowingStream<ChatMessage, Error> {
        AsyncThrowingStream { continuation in
            Task { @Sendable in
                do {
                    let msg = try await generateMessage(history: history, settings: settings)
                    continuation.yield(msg)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
