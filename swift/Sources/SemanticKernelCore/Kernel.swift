import Foundation
import SemanticKernelAbstractions
import Logging

/// Actor-based implementation of `KernelProtocol`.
public actor Kernel: KernelProtocol {
    private var functions: [String: (KernelArguments) async throws -> KernelResult] = [:]
    private var metadataMap: [String: KernelFunctionMetadata] = [:]
    private let services: ServiceCollection
    private let logger: Logger
    private let metrics: MetricsSink
    public nonisolated let memory: MemoryStore?
    public nonisolated var log: Logger { logger }

    init(services: ServiceCollection, logger: Logger, metrics: MetricsSink, memory: MemoryStore?) {
        self.services = services
        self.logger = logger
        self.metrics = metrics
        self.memory = memory
    }

    public func registerFunction(_ name: String, metadata: KernelFunctionMetadata?, handler: @escaping (KernelArguments) async throws -> KernelResult) async {
        functions[name] = handler
        if let meta = metadata {
            metadataMap[name] = meta
        }
    }

    public func registerFunction(_ name: String, handler: @escaping (KernelArguments) async throws -> KernelResult) async {
        await registerFunction(name, metadata: nil, handler: handler)
    }

    public func registerPlugin(_ plugin: KernelPlugin, namespace: String? = nil) async {
        let ns = namespace ?? String(describing: type(of: plugin))
        for descriptor in plugin.descriptors {
            let name = "\(ns).\(descriptor.name)"
            let meta = KernelFunctionMetadata(description: descriptor.description, parameters: descriptor.parameters, returnType: descriptor.returnType)
            await registerFunction(name, metadata: meta, handler: descriptor.handler)
        }
    }

    public func run(functionName: String, arguments: KernelArguments) async throws -> KernelResult {
        try Task.checkCancellation()
        guard let fn = functions[functionName] else {
            throw KernelError.functionNotFound(functionName)
        }
        let serviceId = arguments["serviceId"] ?? "unknown"
        logger.info("Invoking kernel function", metadata: ["function": "\(functionName)", "serviceId": "\(serviceId)"])
        let start = Date()
        let result = try await fn(arguments)
        metrics.record(.callDuration(name: functionName, seconds: Date().timeIntervalSince(start)))
        return result
    }

    public func metadata(for functionName: String) async -> KernelFunctionMetadata? {
        metadataMap[functionName]
    }

    /// Retrieve a registered service by type.
    public func getService<T: Sendable>() async -> T? {
        await services.resolve()
    }

    /// Generate an embedding for the given text and store it in the memory store.
    /// - Returns: The identifier of the stored memory record.
    public func remember(text: String, in collection: String, metadata: [String: String]? = nil) async throws -> MemoryRecordID {
        try Task.checkCancellation()
        guard let embed: EmbeddingGenerationService = await getService() else {
            throw KernelError.serviceNotFound("EmbeddingGenerationService")
        }
        guard let store = memory else {
            throw KernelError.serviceNotFound("MemoryStore")
        }
        let start = Date()
        let vector = try await embed.generateEmbedding(for: text)
        let record = MemoryRecord(id: UUID().uuidString, text: text, embedding: vector, metadata: metadata, timestamp: Date())
        try await store.store(record, in: collection)
        metrics.record(.callDuration(name: "remember", seconds: Date().timeIntervalSince(start)))
        return record.id
    }

    /// Recall the most relevant memories matching the given query text.
    public func recall(query: String, in collection: String, topK: Int, threshold: Double? = nil) async throws -> [MemoryRecord] {
        try Task.checkCancellation()
        guard let embed: EmbeddingGenerationService = await getService() else {
            throw KernelError.serviceNotFound("EmbeddingGenerationService")
        }
        guard let store = memory else {
            throw KernelError.serviceNotFound("MemoryStore")
        }
        let start = Date()
        let vector = try await embed.generateEmbedding(for: query)
        let records = try await store.search(in: collection, embedding: vector, limit: topK)
        metrics.record(.callDuration(name: "recall", seconds: Date().timeIntervalSince(start)))
        guard let t = threshold else { return records }
        return records.filter { rec in
            if let emb = rec.embedding { return cosineSimilarity(vector, emb) >= t }
            return true
        }
    }

    /// Import semantic skill functions from a directory on disk. Each
    /// subdirectory represents a function containing a `.prompt` file and a
    /// `config.json` describing completion settings and description.
    public func importSemanticSkill(from folder: URL, namespace: String? = nil) async throws {
        let ns = namespace ?? folder.lastPathComponent
        let dirs = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for dir in dirs where dir.hasDirectoryPath {
            let functionName = dir.lastPathComponent
            let promptPath = dir.appendingPathComponent("\(functionName).prompt")
            guard FileManager.default.fileExists(atPath: promptPath.path) else { continue }
            let prompt = try String(contentsOf: promptPath, encoding: .utf8)
            let configPath = dir.appendingPathComponent("config.json")
            var description = ""
            var settings: CompletionSettings? = nil
            if FileManager.default.fileExists(atPath: configPath.path) {
                let data = try Data(contentsOf: configPath)
                let cfg = try JSONDecoder().decode(SemanticSkillConfig.self, from: data)
                description = cfg.description ?? ""
                settings = cfg.settings()
            }
            let fullName = "\(ns).\(functionName)"
            let tmpl = prompt
            await registerFunction(fullName, metadata: KernelFunctionMetadata(description: description, parameters: [])) { [weak self] args in
                guard let self = self else { return KernelResult("") }
                guard let service: TextCompletionService = await self.getService() else {
                    throw KernelError.serviceNotFound("TextCompletionService")
                }
                let rendered = try await TemplateEngine.render(tmpl, variables: args.entries, kernel: self)
                let text = try await service.generateText(prompt: rendered, settings: settings)
                return KernelResult(text)
            }
            metadataMap[fullName] = KernelFunctionMetadata(description: description, parameters: [])
        }
    }

    /// Import semantic plugin functions from a directory on disk using the layout
    /// `SkillName/FunctionName/skprompt.txt` and `config.json`.
    public func importSemanticPlugin(at folder: URL, named namespace: String? = nil) async throws {
        let ns = namespace ?? folder.lastPathComponent
        let dirs = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
        for dir in dirs where dir.hasDirectoryPath {
            let functionName = dir.lastPathComponent
            let promptPath = dir.appendingPathComponent("skprompt.txt")
            guard FileManager.default.fileExists(atPath: promptPath.path) else { continue }
            let prompt = try String(contentsOf: promptPath, encoding: .utf8)
            let configPath = dir.appendingPathComponent("config.json")
            var cfg = PromptTemplateConfig()
            if FileManager.default.fileExists(atPath: configPath.path) {
                let data = try Data(contentsOf: configPath)
                cfg = try JSONDecoder().decode(PromptTemplateConfig.self, from: data)
            }

            let fullName = "\(ns).\(functionName)"
            let tmpl = prompt
            let defaults = cfg.defaults()
            let required = cfg.requiredVariables()
            let meta = KernelFunctionMetadata(description: cfg.description ?? "", parameters: cfg.parameters())
            await registerFunction(fullName, metadata: meta) { [weak self] args in
                guard let self = self else { return KernelResult("") }
                guard let service: TextCompletionService = await self.getService() else {
                    throw KernelError.serviceNotFound("TextCompletionService")
                }
                var vars = defaults
                for (k,v) in args.entries { if k != "temperature" && k != "maxTokens" && k != "max_tokens" { vars[k] = v } }
                for req in required { if vars[req] == nil { throw KernelError.missingArgument(req) } }
                let rendered = try await TemplateEngine.render(tmpl, variables: vars, kernel: self)
                let settings = cfg.settings(overrides: args)
                let text = try await service.generateText(prompt: rendered, settings: settings)
                return KernelResult(text)
            }
            metadataMap[fullName] = meta
        }
    }

    public func exportFunctionSchemas(includeSemantic: Bool = true) async -> [FunctionDefinition] {
        metadataMap.map { name, meta in
            meta.toFunctionDefinition(name: name)
        }.sorted { $0.name < $1.name }
    }
}
