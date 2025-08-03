// This test suite verifies the core functionalities of the Kernel.
import XCTest
@testable import SemanticKernelCore
@testable import SemanticKernelAbstractions

final class KernelTests: XCTestCase {
    /// Tests a simple "Hello World" scenario with a custom function.
    func testHelloWorld() async throws {
        var builder = KernelBuilder()
        builder = builder.withFunction("upper") { args in
            let text = args["input"] ?? ""
            return KernelResult(text.uppercased())
        }
        let kernel = await builder.build()
        let result = try await kernel.run(functionName: "upper", arguments: KernelArguments(["input": "hello"]))
        XCTAssertEqual(result.output, "HELLO")
    }

    /// A deterministic embedding service for consistent testing.
    final class DeterministicEmbedding: EmbeddingGenerationService, @unchecked Sendable {
        func generateEmbedding(for text: String) async throws -> [Double] {
            switch text {
            case "a", "hello": return [1,0]
            case "b": return [0,1]
            default: return [0.5,0.5]
            }
        }
    }

    /// Tests the remember and recall functionality of the kernel with a deterministic embedding.
    func testRememberRecall() async throws {
        var builder = KernelBuilder()
        builder = await builder.withService(DeterministicEmbedding() as EmbeddingGenerationService)
        builder = await builder.withService(InMemoryMemoryStore() as MemoryStore)
        let kernel = await builder.build()

        let id = try await kernel.remember(text: "hello", in: "test")
        let results = try await kernel.recall(query: "hello", in: "test", topK: 1)
        XCTAssertEqual(results.first?.id, id)
        XCTAssertEqual(results.first?.text, "hello")
    }

    /// Tests the ranking of recalled items based on similarity.
    func testRecallRanking() async throws {
        var builder = KernelBuilder()
        builder = await builder.withService(DeterministicEmbedding() as EmbeddingGenerationService)
        builder = await builder.withService(InMemoryMemoryStore() as MemoryStore)
        let kernel = await builder.build()

        try await kernel.remember(text: "a", in: "c")
        try await kernel.remember(text: "b", in: "c")
        let results = try await kernel.recall(query: "a", in: "c", topK: 2)
        XCTAssertEqual(results.first?.text, "a")
    }
}
