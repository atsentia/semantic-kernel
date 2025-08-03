import Foundation
import AsyncHTTPClient
import NIOCore
import Logging
import SemanticKernelAbstractions
import SemanticKernelCore

public final class OpenAIChatCompletionService: FunctionAwareChatCompletionService, @unchecked Sendable {
    private let client: OpenAIClient
    private let model: String
    private let metrics: MetricsSink
    public private(set) var lastUsage: Usage?

    public init(apiKey: String? = nil, model: String, baseURL: URL? = nil, apiVersion: String? = nil, httpClient: HTTPClientSending = HTTPClient(eventLoopGroupProvider: .singleton), retryConfig: RetryConfig = RetryConfig(), logger: Logger? = nil, metrics: MetricsSink = NoOpMetricsSink()) {
        self.client = OpenAIClient(apiKey: apiKey, baseURL: baseURL, apiVersion: apiVersion, httpClient: httpClient, retryConfig: retryConfig, logger: logger)
        self.model = model
        self.metrics = metrics
    }

    public func generateMessage(history: [ChatMessage], settings: CompletionSettings?) async throws -> ChatMessage {
        return try await generateMessage(history: history, settings: settings, functions: nil)
    }
    
    public func generateMessage(history: [ChatMessage], settings: CompletionSettings?, functions: [FunctionDefinition]?) async throws -> ChatMessage {
        try Task.checkCancellation()
        
        // Convert chat messages to OpenAI format, preserving tool calls
        let msgs = history.map { msg -> OpenAIMessage in
            if let toolCalls = msg.toolCalls, !toolCalls.isEmpty {
                let openAIToolCalls = toolCalls.map { call in
                    OpenAIToolCall(
                        id: call.id ?? UUID().uuidString, // Use existing ID or generate new one
                        function: OpenAIFunctionCall(
                            name: call.name.replacingOccurrences(of: ".", with: "_"), // Convert dots to underscores for API
                            arguments: call.arguments
                        )
                    )
                }
                return OpenAIMessage(role: msg.role.rawValue, content: msg.content, tool_calls: openAIToolCalls, tool_call_id: msg.toolCallId)
            } else {
                return OpenAIMessage(role: msg.role.rawValue, content: msg.content, tool_call_id: msg.toolCallId)
            }
        }
        
        // Convert function definitions to OpenAI tools format
        // OpenAI requires function names to match ^[a-zA-Z0-9_-]+$ (no dots allowed)
        let tools: [OpenAITool]? = functions?.map { funcDef in
            let properties = funcDef.parameters.properties.mapValues { prop in
                OpenAIParameterProperty(type: prop.type, description: prop.description)
            }
            let parameters = OpenAIFunctionParameters(
                properties: properties,
                required: funcDef.parameters.required ?? []
            )
            let function = OpenAIFunction(
                name: funcDef.name.replacingOccurrences(of: ".", with: "_"), // Replace dots with underscores
                description: funcDef.description,
                parameters: parameters
            )
            return OpenAITool(function: function)
        }
        
        let req = ChatCompletionRequest(
            model: model,
            messages: msgs,
            temperature: settings?.temperature,
            max_tokens: settings?.maxTokens,
            tools: tools,
            tool_choice: tools?.isEmpty == false ? .auto : nil
        )

        let path: String
        var query: [URLQueryItem] = []
        if let ver = client.apiVersion {
            path = "/openai/deployments/\(model)/chat/completions"
            query.append(URLQueryItem(name: "api-version", value: ver))
        } else {
            path = "/v1/chat/completions"
        }

        let start = Date()
        let (status, buffer) = try await client.sendJSON(req, path: path, query: query)
        guard status == .ok else {
            // Log the error response for debugging
            let data = Data(buffer.getBytes(at: 0, length: buffer.readableBytes) ?? [])
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ OpenAI API Error Response: \(errorString)")
            }
            if status == .unauthorized { throw AIServiceError.unauthorized }
            if status == .tooManyRequests { throw AIServiceError.rateLimited }
            throw AIServiceError.badResponse(status: Int(status.code))
        }
        let data = Data(buffer.getBytes(at: 0, length: buffer.readableBytes) ?? [])
        let resp = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        lastUsage = resp.usage
        if let total = resp.usage?.total_tokens {
            metrics.record(.tokensUsed(total))
        }
        metrics.record(.callDuration(name: "chat", seconds: Date().timeIntervalSince(start)))
        guard let first = resp.choices.first else { throw AIServiceError.invalidResponse }
        
        // Convert OpenAI tool calls back to Semantic Kernel format
        // Convert underscores back to dots to match original function names
        let toolCalls: [ToolCall]? = first.message.tool_calls?.map { openAIToolCall in
            ToolCall(
                id: openAIToolCall.id,
                name: openAIToolCall.function.name.replacingOccurrences(of: "_", with: "."),
                arguments: openAIToolCall.function.arguments
            )
        }
        
        return ChatMessage(
            role: ChatRole(rawValue: first.message.role) ?? .assistant,
            content: first.message.content ?? "",
            toolCalls: toolCalls
        )
    }
}
