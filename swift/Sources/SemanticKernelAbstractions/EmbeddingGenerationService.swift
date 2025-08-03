import Foundation

public protocol EmbeddingGenerationService: Sendable {
    func generateEmbedding(for text: String) async throws -> [Double]
}
