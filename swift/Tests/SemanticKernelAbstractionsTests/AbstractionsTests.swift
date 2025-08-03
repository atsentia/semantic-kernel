// This test suite verifies the core functionalities of the SemanticKernelAbstractions module.
import XCTest
@testable import SemanticKernelAbstractions

final class AbstractionsTests: XCTestCase {
    /// Tests the initialization and property assignment of the ChatMessage struct.
    func testChatMessage() {
        let message = ChatMessage(role: .user, content: "Hi")
        XCTAssertEqual(message.role, .user)
        XCTAssertEqual(message.content, "Hi")
        XCTAssertNil(message.toolCalls)
    }

    struct DummyMemoryStore: MemoryStore {
        func store(_ record: MemoryRecord, in collection: String) async throws {}
        func get(id: String, in collection: String) async throws -> MemoryRecord? { nil }
        func search(in collection: String, embedding: [Double], limit: Int) async throws -> [MemoryRecord] { [] }
    }

    /// Tests the conformance of a dummy MemoryStore to the MemoryStore protocol.
    func testConformance() async throws {
        let store = DummyMemoryStore()
        try await store.store(MemoryRecord(id: "1"), in: "c")
        let value = try await store.get(id: "1", in: "c")
        XCTAssertNil(value)
        let results = try await store.search(in: "c", embedding: [0, 0], limit: 1)
        XCTAssertEqual(results.count, 0)
    }
}
