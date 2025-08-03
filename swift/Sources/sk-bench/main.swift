import Foundation
import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions

@main
struct SKBench {
    static func main() async throws {
        let dispatchNs = try await benchmarkPluginDispatch(iterations: 1000)
        let memoryNs = try await benchmarkMemorySearch(iterations: 100, records: 1000)
        let result = [
            "plugin_dispatch_ns_per_op": dispatchNs,
            "memory_search_ns_per_op": memoryNs
        ]
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted])
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }

    static func benchmarkPluginDispatch(iterations: Int) async throws -> Double {
        var builder = KernelBuilder()
        builder = builder.withPlugin(MathPlugin())
        let kernel = await builder.build()
        let args = KernelArguments(["x": "1", "y": "2"])
        let start = DispatchTime.now()
        for _ in 0..<iterations {
            _ = try await kernel.run(functionName: "math.add", arguments: args)
        }
        let end = DispatchTime.now()
        let elapsed = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
        return elapsed / Double(iterations)
    }

    static func benchmarkMemorySearch(iterations: Int, records: Int) async throws -> Double {
        let store = InMemoryMemoryStore()
        let embed = DummyEmbedding()
        // populate
        for i in 0..<records {
            let text = "item\(i)"
            let vector = try await embed.generateEmbedding(for: text)
            let record = MemoryRecord(id: text, text: text, embedding: vector, metadata: nil, timestamp: Date())
            try await store.store(record, in: "bench")
        }
        let query = try await embed.generateEmbedding(for: "query")
        let start = DispatchTime.now()
        for _ in 0..<iterations {
            _ = try await store.search(in: "bench", embedding: query, limit: 5)
        }
        let end = DispatchTime.now()
        let elapsed = Double(end.uptimeNanoseconds - start.uptimeNanoseconds)
        return elapsed / Double(iterations)
    }
}

struct DummyEmbedding: EmbeddingGenerationService {
    func generateEmbedding(for text: String) async throws -> [Double] {
        var hash = UInt64(bitPattern: Int64(text.hashValue))
        var vec: [Double] = []
        for _ in 0..<64 {
            hash = 2862933555777941757 &* hash &+ 3037000493
            vec.append(Double(hash % 1000) / 1000.0)
        }
        return vec
    }
}
