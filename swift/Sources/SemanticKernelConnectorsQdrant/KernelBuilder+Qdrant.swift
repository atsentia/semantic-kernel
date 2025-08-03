import SemanticKernelCore
import Foundation

public extension KernelBuilder {
    mutating func withQdrantMemoryStore(url: URL, apiKey: String? = nil, collection: String = "sk") async -> Self {
        let store = QdrantMemoryStore(url: url, collection: collection, apiKey: apiKey)
        return await withService(store)
    }
}
