import Foundation
import AsyncHTTPClient
import NIOCore
import Logging
import SemanticKernelAbstractions
import SemanticKernelCore

public final class OpenAITextCompletionService: TextCompletionService, @unchecked Sendable {
    private let client: OpenAIClient
    private let model: String
    private let metrics: MetricsSink
    public private(set) var lastUsage: Usage?

    public init(apiKey: String? = nil, model: String, baseURL: URL? = nil, apiVersion: String? = nil, httpClient: HTTPClientSending = HTTPClient(eventLoopGroupProvider: .singleton), retryConfig: RetryConfig = RetryConfig(), logger: Logger? = nil, metrics: MetricsSink = NoOpMetricsSink()) {
        self.client = OpenAIClient(apiKey: apiKey, baseURL: baseURL, apiVersion: apiVersion, httpClient: httpClient, retryConfig: retryConfig, logger: logger)
        self.model = model
        self.metrics = metrics
    }

    public func generateText(prompt: String, settings: CompletionSettings?) async throws -> String {
        try Task.checkCancellation()
        let req = TextCompletionRequest(model: model, prompt: prompt, temperature: settings?.temperature, max_tokens: settings?.maxTokens)

        let path: String
        var query: [URLQueryItem] = []
        if let ver = client.apiVersion {
            path = "/openai/deployments/\(model)/completions"
            query.append(URLQueryItem(name: "api-version", value: ver))
        } else {
            path = "/v1/completions"
        }

        let start = Date()
        let (status, buffer) = try await client.sendJSON(req, path: path, query: query)
        guard status == .ok else {
            if status == .unauthorized { throw AIServiceError.unauthorized }
            if status == .tooManyRequests { throw AIServiceError.rateLimited }
            throw AIServiceError.badResponse(status: Int(status.code))
        }
        let data = Data(buffer.getBytes(at: 0, length: buffer.readableBytes) ?? [])
        let resp = try JSONDecoder().decode(TextCompletionResponse.self, from: data)
        lastUsage = resp.usage
        if let total = resp.usage?.total_tokens { metrics.record(.tokensUsed(total)) }
        metrics.record(.callDuration(name: "text", seconds: Date().timeIntervalSince(start)))
        guard let first = resp.choices.first else { throw AIServiceError.invalidResponse }
        return first.text
    }
}
