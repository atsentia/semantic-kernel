// This test suite verifies the functionality of the QdrantMemoryStore.
import XCTest
import NIOCore
@testable import SemanticKernelConnectorsQdrant
@testable import SemanticKernelAbstractions

final class QdrantMemoryStoreTests: XCTestCase {
    /// Tests the decoding of search results from Qdrant.
    func testSearchDecoding() async throws {
        let json = "{\"result\": [{\"id\": 1, \"payload\": {\"text\": \"hello\"}}]}"
        var buffer = ByteBufferAllocator().buffer(capacity: json.utf8.count)
        buffer.writeString(json)
        let mock = MockHTTPClient(status: .ok, body: buffer)
        let store = QdrantMemoryStore(url: URL(string: "http://localhost:6333")!, client: mock)
        let results = try await store.search(in: "sk", embedding: [0.1,0.2], limit: 1)
        XCTAssertEqual(results.first?.text, "hello")
    }

    /// Tests that a bad response from the Qdrant store throws the correct error.
    func testStoreBadResponse() async throws {
        let mock = MockHTTPClient(status: .unauthorized, body: ByteBuffer())
        let store = QdrantMemoryStore(url: URL(string: "http://localhost:6333")!, client: mock)
        do {
            try await store.store(MemoryRecord(id: "1", text: "hi", embedding: [0], metadata: nil), in: "sk")
            XCTFail("expected error")
        } catch MemoryStoreError.badResponse(let status) {
            XCTAssertEqual(status, 401)
        }
    }
}
