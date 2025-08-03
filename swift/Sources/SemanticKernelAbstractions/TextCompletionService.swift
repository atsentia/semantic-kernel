import Foundation

public protocol TextCompletionService: Sendable {
    func generateText(prompt: String, settings: CompletionSettings?) async throws -> String
    func streamText(prompt: String, settings: CompletionSettings?) -> AsyncThrowingStream<String, Error>
}

public extension TextCompletionService {
    func streamText(prompt: String, settings: CompletionSettings?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { @Sendable in
                do {
                    let text = try await generateText(prompt: prompt, settings: settings)
                    continuation.yield(text)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
