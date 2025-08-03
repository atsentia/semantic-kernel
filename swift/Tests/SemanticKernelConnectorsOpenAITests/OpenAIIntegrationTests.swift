// This test suite contains integration tests for the OpenAI connector.
import XCTest
@testable import SemanticKernelConnectorsOpenAI
import SemanticKernelAbstractions

final class OpenAIIntegrationTests: XCTestCase {
    /// Tests live chat functionality if an OpenAI API key is present in the environment.
    func testLiveChatIfKeyPresent() async throws {
        guard let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            throw XCTSkip("no key")
        }
        let svc = OpenAIChatCompletionService(apiKey: key, model: "gpt-3.5-turbo")
        let msg = try await svc.generateMessage(history: [ChatMessage(role: .user, content: "Hello")], settings: nil)
        XCTAssertFalse(msg.content.isEmpty)
    }
}
