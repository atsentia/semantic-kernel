// This test suite verifies the functionality of InMemoryMemoryStore.
import XCTest
@testable import SemanticKernelCore
@testable import SemanticKernelAbstractions

final class InMemoryMemoryStoreTests: XCTestCase {
    /// Tests storing and retrieving a MemoryRecord.
    func testStoreAndGet() async throws {
        let store = InMemoryMemoryStore()
        let record = MemoryRecord(id: "1", text: "hi", embedding: [1,0])
        try await store.store(record, in: "a")
        let fetched = try await store.get(id: "1", in: "a")
        XCTAssertEqual(fetched?.text, "hi")
    }

    /// Tests cosine similarity search functionality.
    func testCosineSearch() async throws {
        let store = InMemoryMemoryStore()
        try await store.store(MemoryRecord(id: "a", embedding: [1.0, 0.0]), in: "test")
        try await store.store(MemoryRecord(id: "b", embedding: [0.0, 1.0]), in: "test")

        let results = try await store.search(in: "test", embedding: [0.8, 0.2], limit: 1)
        XCTAssertEqual(results.first?.id, "a")
    }

    /// Tests that collections are isolated from each other.
    func testCollectionsIsolated() async throws {
        let store = InMemoryMemoryStore()
        try await store.store(MemoryRecord(id: "1", text: "c1", embedding: [1,0]), in: "col1")
        try await store.store(MemoryRecord(id: "1", text: "c2", embedding: [0,1]), in: "col2")

        let r1 = try await store.get(id: "1", in: "col1")
        let r2 = try await store.get(id: "1", in: "col2")
        XCTAssertEqual(r1?.text, "c1")
        XCTAssertEqual(r2?.text, "c2")
    }
}
