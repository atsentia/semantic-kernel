import Foundation

@main
struct HelloMCPMain {
    static func main() async {
        let server = HelloMCPServer()
        await server.run()
    }
}

// MARK: - MCP Protocol Types

struct JSONRPCRequest: Codable {
    let jsonrpc: String
    let id: JSONRPCId?
    let method: String
    let params: AnyCodable?
}

struct JSONRPCResponse: Codable {
    let jsonrpc: String
    let id: JSONRPCId?
    let result: AnyCodable?
    let error: JSONRPCError?
    
    init(id: JSONRPCId?, result: AnyCodable? = nil, error: JSONRPCError? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = error
    }
}

struct JSONRPCError: Codable {
    let code: Int
    let message: String
    let data: AnyCodable?
    
    init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

enum JSONRPCId: Codable {
    case string(String)
    case number(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .number(intValue)
        } else {
            throw DecodingError.typeMismatch(JSONRPCId.self, 
                DecodingError.Context(codingPath: decoder.codingPath, 
                                    debugDescription: "Invalid JSON-RPC ID"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        }
    }
}

// Type-erased wrapper for any Codable type
struct AnyCodable: Codable {
    let value: Any
    
    init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    init(any value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode([String: AnyCodable].self) {
            self.value = value
        } else if let value = try? container.decode([AnyCodable].self) {
            self.value = value
        } else if let value = try? container.decode(String.self) {
            self.value = value
        } else if let value = try? container.decode(Int.self) {
            self.value = value
        } else if let value = try? container.decode(Double.self) {
            self.value = value
        } else if let value = try? container.decode(Bool.self) {
            self.value = value
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self,
                DecodingError.Context(codingPath: decoder.codingPath,
                                    debugDescription: "Cannot decode AnyCodable"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let value as String:
            try container.encode(value)
        case let value as Int:
            try container.encode(value)
        case let value as Double:
            try container.encode(value)
        case let value as Bool:
            try container.encode(value)
        case let value as [String: AnyCodable]:
            try container.encode(value)
        case let value as [AnyCodable]:
            try container.encode(value)
        case let value as [String: Any]:
            // Convert [String: Any] to [String: AnyCodable]
            let convertedDict = value.mapValues { AnyCodable(any: $0) }
            try container.encode(convertedDict)
        case let value as [Any]:
            // Convert [Any] to [AnyCodable]
            let convertedArray = value.map { AnyCodable(any: $0) }
            try container.encode(convertedArray)
        default:
            let context = EncodingError.Context(codingPath: encoder.codingPath,
                                              debugDescription: "Cannot encode value of type \(type(of: value))")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - MCP Server Implementation

struct HelloMCPServer {
    private let protocolVersion = "2024-11-05"
    
    func run() async {
        FileHandle.standardError.write("Hello MCP Server starting...\n".data(using: .utf8)!)
        FileHandle.standardError.write("Protocol version: \(protocolVersion)\n".data(using: .utf8)!)
        
        while let line = readLine() {
            await handleRequest(line)
        }
    }
    
    private func handleRequest(_ line: String) async {
        guard let data = line.data(using: .utf8) else {
            sendError(id: nil, code: -32700, message: "Parse error: Invalid UTF-8")
            return
        }
        
        let request: JSONRPCRequest
        do {
            request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
        } catch {
            sendError(id: nil, code: -32700, message: "Parse error: \(error.localizedDescription)")
            return
        }
        
        await handleMethod(request)
    }
    
    private func handleMethod(_ request: JSONRPCRequest) async {
        switch request.method {
        case "initialize":
            handleInitialize(request)
        case "tools/list":
            handleToolsList(request)
        case "tools/call":
            await handleToolsCall(request)
        case "resources/list":
            handleResourcesList(request)
        case "prompts/list":
            handlePromptsList(request)
        default:
            sendError(id: request.id, code: -32601, message: "Method not found: \(request.method)")
        }
    }
    
    private func handleInitialize(_ request: JSONRPCRequest) {
        let result: [String: Any] = [
            "protocolVersion": protocolVersion,
            "capabilities": [
                "tools": [:],
                "resources": [:],
                "prompts": [:]
            ],
            "serverInfo": [
                "name": "hello-mcp-server",
                "version": "1.0.0",
                "description": "A simple Hello World MCP server demonstrating basic protocol features"
            ]
        ]
        
        sendResult(id: request.id, result: result)
    }
    
    private func handleToolsList(_ request: JSONRPCRequest) {
        let tools: [[String: Any]] = [
            [
                "name": "hello",
                "description": "Return a friendly greeting message",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "name": [
                            "type": "string",
                            "description": "Name to greet (optional, defaults to 'World')"
                        ]
                    ]
                ]
            ],
            [
                "name": "echo",
                "description": "Echo back the provided message",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "message": [
                            "type": "string",
                            "description": "Message to echo back"
                        ]
                    ],
                    "required": ["message"]
                ]
            ],
            [
                "name": "add",
                "description": "Add two numbers together",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "a": [
                            "type": "number",
                            "description": "First number"
                        ],
                        "b": [
                            "type": "number",
                            "description": "Second number"
                        ]
                    ],
                    "required": ["a", "b"]
                ]
            ],
            [
                "name": "get_time",
                "description": "Get the current date and time",
                "inputSchema": [
                    "type": "object",
                    "properties": [:]
                ]
            ]
        ]
        
        let result: [String: Any] = [
            "tools": tools
        ]
        
        sendResult(id: request.id, result: result)
    }
    
    private func handleToolsCall(_ request: JSONRPCRequest) async {
        guard let params = request.params?.value as? [String: AnyCodable],
              let toolName = params["name"]?.value as? String else {
            sendError(id: request.id, code: -32602, message: "Invalid parameters: missing tool name")
            return
        }
        
        let arguments = params["arguments"]?.value as? [String: AnyCodable] ?? [:]
        
        switch toolName {
        case "hello":
            let name = arguments["name"]?.value as? String ?? "World"
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": "Hello, \(name)! 👋 This is a greeting from the Hello MCP Server."
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
            
        case "echo":
            guard let message = arguments["message"]?.value as? String else {
                sendError(id: request.id, code: -32602, message: "Invalid parameters: missing message")
                return
            }
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text", 
                        "text": "Echo: \(message)"
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
            
        case "add":
            guard let aValue = arguments["a"]?.value,
                  let bValue = arguments["b"]?.value else {
                sendError(id: request.id, code: -32602, message: "Invalid parameters: missing a or b")
                return
            }
            
            let a: Double
            let b: Double
            
            if let aDouble = aValue as? Double {
                a = aDouble
            } else if let aInt = aValue as? Int {
                a = Double(aInt)
            } else {
                sendError(id: request.id, code: -32602, message: "Invalid parameters: 'a' must be a number")
                return
            }
            
            if let bDouble = bValue as? Double {
                b = bDouble
            } else if let bInt = bValue as? Int {
                b = Double(bInt)
            } else {
                sendError(id: request.id, code: -32602, message: "Invalid parameters: 'b' must be a number")
                return
            }
            
            let sum = a + b
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": "\(a) + \(b) = \(sum)"
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
            
        case "get_time":
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .full
            let timeString = formatter.string(from: Date())
            
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": "Current date and time: \(timeString)"
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
            
        default:
            sendError(id: request.id, code: -32601, message: "Unknown tool: \(toolName)")
        }
    }
    
    private func handleResourcesList(_ request: JSONRPCRequest) {
        let result: [String: Any] = [
            "resources": []
        ]
        sendResult(id: request.id, result: result)
    }
    
    private func handlePromptsList(_ request: JSONRPCRequest) {
        let result: [String: Any] = [
            "prompts": []
        ]
        sendResult(id: request.id, result: result)
    }
    
    private func sendResult(id: JSONRPCId?, result: [String: Any]) {
        let response = JSONRPCResponse(id: id, result: AnyCodable(any: result))
        sendResponse(response)
    }
    
    private func sendError(id: JSONRPCId?, code: Int, message: String, data: Any? = nil) {
        let error = JSONRPCError(code: code, message: message, data: data.map { AnyCodable(any: $0) })
        let response = JSONRPCResponse(id: id, error: error)
        sendResponse(response)
    }
    
    private func sendResponse(_ response: JSONRPCResponse) {
        do {
            let data = try JSONEncoder().encode(response)
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
                fflush(stdout)
            }
        } catch {
            FileHandle.standardError.write("Error encoding response: \(error)\n".data(using: .utf8)!)
        }
    }
}