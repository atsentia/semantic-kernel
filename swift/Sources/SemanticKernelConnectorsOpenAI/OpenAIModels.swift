import Foundation

public struct Usage: Codable {
    public let prompt_tokens: Int?
    public let completion_tokens: Int?
    public let total_tokens: Int?
}

public struct OpenAIMessage: Codable {
    public let role: String
    public let content: String?
    public let tool_calls: [OpenAIToolCall]?
    public let tool_call_id: String?
    
    public init(role: String, content: String? = nil, tool_calls: [OpenAIToolCall]? = nil, tool_call_id: String? = nil) {
        self.role = role
        self.content = content
        self.tool_calls = tool_calls
        self.tool_call_id = tool_call_id
    }
}

public struct ChatCompletionRequest: Codable {
    public let model: String
    public let messages: [OpenAIMessage]
    public let temperature: Double?
    public let max_tokens: Int?
    public let tools: [OpenAITool]?
    public let tool_choice: ToolChoice?
    
    public init(model: String, messages: [OpenAIMessage], temperature: Double? = nil, max_tokens: Int? = nil, tools: [OpenAITool]? = nil, tool_choice: ToolChoice? = nil) {
        self.model = model
        self.messages = messages
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.tools = tools
        self.tool_choice = tool_choice
    }
}

public struct ChatCompletionChoice: Codable {
    public let message: OpenAIMessage
}

public struct ChatCompletionResponse: Codable {
    public let choices: [ChatCompletionChoice]
    public let usage: Usage?
}

public struct TextCompletionRequest: Codable {
    public let model: String
    public let prompt: String
    public let temperature: Double?
    public let max_tokens: Int?
}

public struct TextCompletionChoice: Codable {
    public let text: String
}

public struct TextCompletionResponse: Codable {
    public let choices: [TextCompletionChoice]
    public let usage: Usage?
}

public struct EmbeddingRequest: Codable {
    public let input: String
    public let model: String
}

public struct EmbeddingData: Codable {
    public let embedding: [Double]
}

public struct EmbeddingResponse: Codable {
    public let data: [EmbeddingData]
    public let usage: Usage?
}

// MARK: - Function Calling Support

public struct OpenAITool: Codable {
    public let type: String
    public let function: OpenAIFunction
    
    public init(function: OpenAIFunction) {
        self.type = "function"
        self.function = function
    }
}

public struct OpenAIFunction: Codable {
    public let name: String
    public let description: String
    public let parameters: OpenAIFunctionParameters
    
    public init(name: String, description: String, parameters: OpenAIFunctionParameters) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }
}

public struct OpenAIFunctionParameters: Codable {
    public let type: String
    public let properties: [String: OpenAIParameterProperty]
    public let required: [String]
    
    public init(properties: [String: OpenAIParameterProperty], required: [String] = []) {
        self.type = "object"
        self.properties = properties
        self.required = required
    }
}

public struct OpenAIParameterProperty: Codable {
    public let type: String
    public let description: String
    
    public init(type: String, description: String) {
        self.type = type
        self.description = description
    }
}

public struct OpenAIToolCall: Codable {
    public let id: String
    public let type: String
    public let function: OpenAIFunctionCall
    
    public init(id: String, function: OpenAIFunctionCall) {
        self.id = id
        self.type = "function"
        self.function = function
    }
}

public struct OpenAIFunctionCall: Codable {
    public let name: String
    public let arguments: String
    
    public init(name: String, arguments: String) {
        self.name = name
        self.arguments = arguments
    }
}

public enum ToolChoice: Codable {
    case none
    case auto
    case required
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none:
            try container.encode("none")
        case .auto:
            try container.encode("auto")
        case .required:
            try container.encode("required")
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        switch string {
        case "none": self = .none
        case "auto": self = .auto
        case "required": self = .required
        default: throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid tool choice: \(string)"))
        }
    }
}
