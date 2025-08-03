import Foundation
import SemanticKernelAbstractions

/// Simple in-memory `MemoryStore` optimized for collections up to ~10k vectors.
/// It performs brute-force cosine similarity search over the stored embeddings.
public actor InMemoryMemoryStore: MemoryStore {
    private var collections: [String: [MemoryRecordID: MemoryRecord]] = [:]

    public init() {}

    public func store(_ record: MemoryRecord, in collection: String) async throws {
        try Task.checkCancellation()
        var bucket = collections[collection] ?? [:]
        bucket[record.id] = record
        collections[collection] = bucket
    }

    public func get(id: String, in collection: String) async throws -> MemoryRecord? {
        try Task.checkCancellation()
        return collections[collection]?[id]
    }

    public func search(in collection: String, embedding query: [Double], limit: Int) async throws -> [MemoryRecord] {
        try Task.checkCancellation()
        guard let bucket = collections[collection], !bucket.isEmpty else { return [] }
        var scored: [(record: MemoryRecord, score: Double)] = []
        scored.reserveCapacity(bucket.count)
        for record in bucket.values {
            if let emb = record.embedding, emb.count == query.count {
                let score = cosineSimilarity(query, emb)
                scored.append((record, score))
            }
        }
        scored.sort { $0.score > $1.score }
        return scored.prefix(limit).map { $0.record }
    }
}
