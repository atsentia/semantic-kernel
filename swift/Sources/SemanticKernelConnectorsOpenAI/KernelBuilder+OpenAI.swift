import SemanticKernelCore

public extension KernelBuilder {
    mutating func withOpenAIChatCompletion(apiKey: String, model: String) async -> Self {
        let service = OpenAIChatCompletionService(apiKey: apiKey, model: model)
        return await withService(service)
    }

    mutating func withOpenAITextCompletion(apiKey: String, model: String) async -> Self {
        let service = OpenAITextCompletionService(apiKey: apiKey, model: model)
        return await withService(service)
    }

    mutating func withOpenAIEmbedding(apiKey: String, model: String) async -> Self {
        let service = OpenAIEmbeddingService(apiKey: apiKey, model: model)
        return await withService(service)
    }
}
