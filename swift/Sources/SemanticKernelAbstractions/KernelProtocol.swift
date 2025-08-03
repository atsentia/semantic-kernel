import Foundation

public protocol KernelProtocol: Sendable {
    func run(functionName: String, arguments: KernelArguments) async throws -> KernelResult
    func registerFunction(_ name: String, metadata: KernelFunctionMetadata?, handler: @escaping @Sendable (KernelArguments) async throws -> KernelResult) async
    func registerFunction(_ name: String, handler: @escaping @Sendable (KernelArguments) async throws -> KernelResult) async
    func registerPlugin(_ plugin: KernelPlugin, namespace: String?) async
    func importSemanticSkill(from folder: URL, namespace: String?) async throws
    func importSemanticPlugin(at folder: URL, named namespace: String?) async throws
    func metadata(for functionName: String) async -> KernelFunctionMetadata?

    var memory: MemoryStore? { get }
    func remember(text: String, in collection: String, metadata: [String: String]?) async throws -> MemoryRecordID
    func recall(query: String, in collection: String, topK: Int, threshold: Double?) async throws -> [MemoryRecord]
}

public extension KernelProtocol {
    func registerFunction(_ name: String, handler: @escaping @Sendable (KernelArguments) async throws -> KernelResult) async {
        await registerFunction(name, metadata: nil, handler: handler)
    }

    func importSemanticPlugin(at folder: URL, named namespace: String? = nil) async throws {
        try await self.importSemanticPlugin(at: folder, named: namespace)
    }

    func remember(text: String, in collection: String, metadata: [String: String]? = nil) async throws -> MemoryRecordID {
        try await self.remember(text: text, in: collection, metadata: metadata)
    }

    func recall(query: String, in collection: String, topK: Int, threshold: Double? = nil) async throws -> [MemoryRecord] {
        try await self.recall(query: query, in: collection, topK: topK, threshold: threshold)
    }
}
