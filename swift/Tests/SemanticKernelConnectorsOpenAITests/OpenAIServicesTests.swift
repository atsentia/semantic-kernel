// This test suite verifies the functionality of various OpenAI services and their interactions.
import XCTest
import NIOCore
@testable import SemanticKernelConnectorsOpenAI
@testable import SemanticKernelAbstractions

final class OpenAIServicesTests: XCTestCase {
    /// Tests the decoding of a chat completion response.
    func testChatCompletionDecoding() async throws {
        let resp = ChatCompletionResponse(choices: [ChatCompletionChoice(message: OpenAIMessage(role: "assistant", content: "hi"))], usage: Usage(prompt_tokens: 1, completion_tokens: 2, total_tokens: 3))
        let data = try JSONEncoder().encode(resp)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        let mock = MockHTTPClient(status: .ok, body: buffer)
        let service = OpenAIChatCompletionService(apiKey: "k", model: "m", httpClient: mock)
        let msg = try await service.generateMessage(history: [], settings: nil)
        XCTAssertEqual(msg.content, "hi")
        XCTAssertEqual(service.lastUsage?.total_tokens, 3)
    }

    /// Tests that a 401 Unauthorized response from the text completion service throws the correct error.
    func testTextCompletion401() async throws {
        let buffer = ByteBuffer(string: "")
        let mock = MockHTTPClient(status: .unauthorized, body: buffer)
        let service = OpenAITextCompletionService(apiKey: "k", model: "m", httpClient: mock)
        do {
            _ = try await service.generateText(prompt: "p", settings: nil)
            XCTFail("expected error")
        } catch AIServiceError.unauthorized {}
    }

    /// Tests that a 429 Too Many Requests response from the embedding service throws the correct error.
    func testEmbedding429() async throws {
        let buffer = ByteBuffer(string: "")
        let mock = MockHTTPClient(status: .tooManyRequests, body: buffer)
        let service = OpenAIEmbeddingService(apiKey: "k", model: "m", httpClient: mock)
        do {
            _ = try await service.generateEmbedding(for: "hi")
            XCTFail("expected error")
        } catch AIServiceError.rateLimited {}
    }

    /// Tests the decoding of an embedding response.
    func testEmbeddingDecode() async throws {
        let resp = EmbeddingResponse(data: [EmbeddingData(embedding: [0.1,0.2])], usage: nil)
        let data = try JSONEncoder().encode(resp)
        var buffer = ByteBufferAllocator().buffer(capacity: data.count)
        buffer.writeBytes(data)
        let mock = MockHTTPClient(status: .ok, body: buffer)
        let service = OpenAIEmbeddingService(apiKey: "k", model: "m", httpClient: mock)
        let vec = try await service.generateEmbedding(for: "hi")
        XCTAssertEqual(vec[0], 0.1, accuracy: 0.0001)
    }

    /// Tests the retry mechanism for transient errors.
    func testRetry() async throws {
        let okResp = ChatCompletionResponse(choices: [ChatCompletionChoice(message: OpenAIMessage(role: "assistant", content: "hi"))], usage: nil)
        let okData = try JSONEncoder().encode(okResp)
        var okBuf = ByteBufferAllocator().buffer(capacity: okData.count)
        okBuf.writeBytes(okData)
        let mock = SequenceMockHTTPClient(responses: [(.internalServerError, ByteBuffer()), (.ok, okBuf)])
        let service = OpenAIChatCompletionService(apiKey: "k", model: "m", httpClient: mock, retryConfig: RetryConfig(maxRetries: 1))
        _ = try await service.generateMessage(history: [], settings: nil)
        XCTAssertEqual(mock.requests.count, 2)
    }

    /// Tests the retry mechanism with backoff for 429 Too Many Requests errors.
    func testRetry429Backoff() async throws {
        let okResp = ChatCompletionResponse(choices: [ChatCompletionChoice(message: OpenAIMessage(role: "assistant", content: "hi"))], usage: nil)
        let okData = try JSONEncoder().encode(okResp)
        var okBuf = ByteBufferAllocator().buffer(capacity: okData.count)
        okBuf.writeBytes(okData)
        let mock = SequenceMockHTTPClient(responses: [(.tooManyRequests, ByteBuffer()), (.ok, okBuf)])
        let service = OpenAIChatCompletionService(apiKey: "k", model: "m", httpClient: mock, retryConfig: RetryConfig(maxRetries: 2))
        _ = try await service.generateMessage(history: [], settings: nil)
        XCTAssertEqual(mock.requests.count, 2)
    }

    /// Tests that the Azure endpoint URL is constructed correctly.
    func testAzureEndpointURL() async throws {
        let resp = ChatCompletionResponse(choices: [ChatCompletionChoice(message: OpenAIMessage(role: "assistant", content: "hi"))], usage: nil)
        let data = try JSONEncoder().encode(resp)
        var buf = ByteBufferAllocator().buffer(capacity: data.count)
        buf.writeBytes(data)
        let mock = SequenceMockHTTPClient(responses: [(.ok, buf)])
        let base = URL(string: "https://example.openai.azure.com")!
        let service = OpenAIChatCompletionService(apiKey: "k", model: "m", baseURL: base, apiVersion: "2023-06-01", httpClient: mock)
        _ = try await service.generateMessage(history: [], settings: nil)
        XCTAssertEqual(mock.requests.first?.url, "https://example.openai.azure.com/openai/deployments/m/chat/completions?api-version=2023-06-01")
    }
}
