//
// MCP Protocol Shared Components
// Reusable MCP protocol types and utilities for both CLI servers and GUI apps
//

import Foundation

// MARK: - MCP Protocol Types

public struct JSONRPCRequest: Codable {
    public let jsonrpc: String
    public let id: JSONRPCId?
    public let method: String
    public let params: AnyCodable?
    
    public init(id: JSONRPCId?, method: String, params: AnyCodable? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.method = method
        self.params = params
    }
}

public struct JSONRPCResponse: Codable {
    public let jsonrpc: String
    public let id: JSONRPCId?
    public let result: AnyCodable?
    public let error: JSONRPCError?
    
    public init(id: JSONRPCId?, result: AnyCodable? = nil, error: JSONRPCError? = nil) {
        self.jsonrpc = "2.0"
        self.id = id
        self.result = result
        self.error = error
    }
}

public struct JSONRPCError: Codable {
    public let code: Int
    public let message: String
    public let data: AnyCodable?
    
    public init(code: Int, message: String, data: AnyCodable? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public enum JSONRPCId: Codable {
    case string(String)
    case number(Int)
    
    public init(from decoder: Decoder) throws {
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
    
    public func encode(to encoder: Encoder) throws {
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
public struct AnyCodable: Codable {
    public let value: Any
    
    public init<T: Codable>(_ value: T) {
        self.value = value
    }
    
    public init(any value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
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
    
    public func encode(to encoder: Encoder) throws {
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
            let convertedDict = value.mapValues { AnyCodable(any: $0) }
            try container.encode(convertedDict)
        case let value as [Any]:
            let convertedArray = value.map { AnyCodable(any: $0) }
            try container.encode(convertedArray)
        default:
            let context = EncodingError.Context(codingPath: encoder.codingPath,
                                              debugDescription: "Cannot encode value of type \(type(of: value))")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - MCP Tool Definitions

public struct MCPTool: Codable, Sendable {
    public let name: String
    public let description: String
    public let inputSchema: String // Store as JSON string for Sendable compliance
    
    public init(name: String, description: String, inputSchema: [String: Any]) {
        self.name = name
        self.description = description
        
        // Convert schema to JSON string
        if let jsonData = try? JSONSerialization.data(withJSONObject: inputSchema),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            self.inputSchema = jsonString
        } else {
            self.inputSchema = "{}"
        }
    }
    
    public var schemaDict: [String: Any] {
        guard let data = inputSchema.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
}

// MARK: - Common Tool Definitions

public enum MCPFilesystemTools {
    public static let readFile = MCPTool(
        name: "read_file",
        description: "Securely read the contents of a text file (max 10MB)",
        inputSchema: [
            "type": "object",
            "properties": [
                "path": [
                    "type": "string",
                    "description": "Path to the file to read"
                ]
            ],
            "required": ["path"]
        ]
    )
    
    public static let writeFile = MCPTool(
        name: "write_file",
        description: "Securely write content to a file (creates directories if needed)",
        inputSchema: [
            "type": "object",
            "properties": [
                "path": [
                    "type": "string",
                    "description": "Path to the file to write"
                ],
                "content": [
                    "type": "string",
                    "description": "Content to write to the file"
                ]
            ],
            "required": ["path", "content"]
        ]
    )
    
    public static let listDirectory = MCPTool(
        name: "list_directory",
        description: "List contents of a directory with file information",
        inputSchema: [
            "type": "object",
            "properties": [
                "path": [
                    "type": "string",
                    "description": "Path to the directory to list (defaults to current directory)"
                ]
            ]
        ]
    )
    
    public static let createDirectory = MCPTool(
        name: "create_directory",
        description: "Create a new directory (creates parent directories if needed)",
        inputSchema: [
            "type": "object",
            "properties": [
                "path": [
                    "type": "string",
                    "description": "Path to the directory to create"
                ]
            ],
            "required": ["path"]
        ]
    )
    
    public static let getFileInfo = MCPTool(
        name: "get_file_info",
        description: "Get detailed information about a file or directory",
        inputSchema: [
            "type": "object",
            "properties": [
                "path": [
                    "type": "string",
                    "description": "Path to the file or directory"
                ]
            ],
            "required": ["path"]
        ]
    )
    
    public static let searchFiles = MCPTool(
        name: "search_files",
        description: "Search for files by name pattern in a directory",
        inputSchema: [
            "type": "object",
            "properties": [
                "directory": [
                    "type": "string",
                    "description": "Directory to search in (defaults to current directory)"
                ],
                "pattern": [
                    "type": "string",
                    "description": "File name pattern to search for (supports wildcards like *.txt)"
                ],
                "recursive": [
                    "type": "boolean",
                    "description": "Whether to search recursively (defaults to false)"
                ]
            ],
            "required": ["pattern"]
        ]
    )
    
    public static let allTools: [MCPTool] = [
        readFile, writeFile, listDirectory, createDirectory, getFileInfo, searchFiles
    ]
}