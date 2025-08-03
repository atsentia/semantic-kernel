import Foundation

public protocol MemoryStore: Sendable {
    /// Store a memory record in the given collection.
    func store(_ record: MemoryRecord, in collection: String) async throws

    /// Retrieve a record by id from the specified collection.
    func get(id: String, in collection: String) async throws -> MemoryRecord?

    /// Search the store using cosine similarity against the provided embedding
    /// vector within the collection. Returns up to `limit` records ordered by
    /// relevance.
    func search(in collection: String, embedding: [Double], limit: Int) async throws -> [MemoryRecord]
}
