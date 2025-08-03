import Foundation

@main
struct FilesystemMCPMain {
    static func main() async {
        let server = FilesystemMCPServer()
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

// MARK: - Security Manager

class SecurityManager {
    private var allowedPaths: Set<String> = []
    private let maxFileSize: Int = 10 * 1024 * 1024 // 10MB limit
    private let maxDirectoryDepth: Int = 10
    
    init() {
        // Initialize with safe default paths
        setupDefaultPaths()
    }
    
    private func setupDefaultPaths() {
        // Start with current working directory
        let currentDir = FileManager.default.currentDirectoryPath
        allowedPaths.insert(currentDir)
        
        // Allow user's Documents directory
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                       in: .userDomainMask).first?.path {
            allowedPaths.insert(documentsPath)
        }
        
        // Allow user's Desktop directory
        if let desktopPath = FileManager.default.urls(for: .desktopDirectory, 
                                                     in: .userDomainMask).first?.path {
            allowedPaths.insert(desktopPath)
        }
        
        // Allow temporary directory for scratch work
        let tempPath = NSTemporaryDirectory()
        allowedPaths.insert(tempPath)
        
        FileHandle.standardError.write("Initialized with allowed paths:\n".data(using: .utf8)!)
        for path in allowedPaths.sorted() {
            FileHandle.standardError.write("  - \(path)\n".data(using: .utf8)!)
        }
    }
    
    func isPathAllowed(_ path: String) -> Bool {
        let normalizedPath = URL(fileURLWithPath: path).standardized.path
        
        // Check if path is within any allowed directory
        for allowedPath in allowedPaths {
            let normalizedAllowed = URL(fileURLWithPath: allowedPath).standardized.path
            if normalizedPath.hasPrefix(normalizedAllowed) {
                return true
            }
        }
        
        return false
    }
    
    func validateFileSize(_ path: String) -> Bool {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = attributes[.size] as? Int {
                return fileSize <= maxFileSize
            }
        } catch {
            return false
        }
        return true
    }
    
    func validateDirectoryDepth(_ path: String) -> Bool {
        let components = URL(fileURLWithPath: path).pathComponents
        return components.count <= maxDirectoryDepth
    }
    
    func sanitizePath(_ path: String) -> String? {
        // Remove any potentially dangerous sequences
        let sanitized = path
            .replacingOccurrences(of: "../", with: "")
            .replacingOccurrences(of: "./", with: "")
            .replacingOccurrences(of: "//", with: "/")
        
        return sanitized.isEmpty ? nil : sanitized
    }
}

// MARK: - Filesystem MCP Server

struct FilesystemMCPServer {
    private let protocolVersion = "2024-11-05"
    private let securityManager = SecurityManager()
    
    func run() async {
        FileHandle.standardError.write("Filesystem MCP Server starting...\n".data(using: .utf8)!)
        FileHandle.standardError.write("Protocol version: \(protocolVersion)\n".data(using: .utf8)!)
        FileHandle.standardError.write("Security: Path-based access control enabled\n".data(using: .utf8)!)
        
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
                "tools": [:]
            ],
            "serverInfo": [
                "name": "filesystem-mcp-server",
                "version": "1.0.0",
                "description": "A secure filesystem MCP server with path-based access control"
            ]
        ]
        
        sendResult(id: request.id, result: result)
    }
    
    private func handleToolsList(_ request: JSONRPCRequest) {
        let tools: [[String: Any]] = [
            [
                "name": "read_file",
                "description": "Securely read the contents of a text file (max 10MB)",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "Path to the file to read"
                        ]
                    ],
                    "required": ["path"]
                ]
            ],
            [
                "name": "write_file", 
                "description": "Securely write content to a file (creates directories if needed)",
                "inputSchema": [
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
            ],
            [
                "name": "list_directory",
                "description": "List contents of a directory with file information",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "Path to the directory to list (defaults to current directory)"
                        ]
                    ]
                ]
            ],
            [
                "name": "create_directory",
                "description": "Create a new directory (creates parent directories if needed)",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "Path to the directory to create"
                        ]
                    ],
                    "required": ["path"]
                ]
            ],
            [
                "name": "get_file_info",
                "description": "Get detailed information about a file or directory",
                "inputSchema": [
                    "type": "object",
                    "properties": [
                        "path": [
                            "type": "string",
                            "description": "Path to the file or directory"
                        ]
                    ],
                    "required": ["path"]
                ]
            ],
            [
                "name": "search_files",
                "description": "Search for files by name pattern in a directory",
                "inputSchema": [
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
        case "read_file":
            await handleReadFile(request: request, arguments: arguments)
        case "write_file":
            await handleWriteFile(request: request, arguments: arguments)
        case "list_directory":
            await handleListDirectory(request: request, arguments: arguments)
        case "create_directory":
            await handleCreateDirectory(request: request, arguments: arguments)
        case "get_file_info":
            await handleGetFileInfo(request: request, arguments: arguments)
        case "search_files":
            await handleSearchFiles(request: request, arguments: arguments)
        default:
            sendError(id: request.id, code: -32601, message: "Unknown tool: \(toolName)")
        }
    }
    
    // MARK: - Tool Implementations
    
    private func handleReadFile(request: JSONRPCRequest, arguments: [String: AnyCodable]) async {
        guard let pathString = arguments["path"]?.value as? String else {
            sendError(id: request.id, code: -32602, message: "Invalid parameters: missing path")
            return
        }
        
        guard let sanitizedPath = securityManager.sanitizePath(pathString) else {
            sendError(id: request.id, code: -32602, message: "Security error: invalid path")
            return
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            sendError(id: request.id, code: -32602, message: "Security error: path not allowed")
            return
        }
        
        guard securityManager.validateFileSize(sanitizedPath) else {
            sendError(id: request.id, code: -32602, message: "Security error: file too large (max 10MB)")
            return
        }
        
        do {
            let content = try String(contentsOfFile: sanitizedPath, encoding: .utf8)
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": content
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
        } catch {
            sendError(id: request.id, code: -32000, message: "File read error: \(error.localizedDescription)")
        }
    }
    
    private func handleWriteFile(request: JSONRPCRequest, arguments: [String: AnyCodable]) async {
        guard let pathString = arguments["path"]?.value as? String,
              let content = arguments["content"]?.value as? String else {
            sendError(id: request.id, code: -32602, message: "Invalid parameters: missing path or content")
            return
        }
        
        guard let sanitizedPath = securityManager.sanitizePath(pathString) else {
            sendError(id: request.id, code: -32602, message: "Security error: invalid path")
            return
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            sendError(id: request.id, code: -32602, message: "Security error: path not allowed")
            return
        }
        
        // Create parent directories if needed
        let parentDirectory = URL(fileURLWithPath: sanitizedPath).deletingLastPathComponent().path
        do {
            try FileManager.default.createDirectory(atPath: parentDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
        } catch {
            sendError(id: request.id, code: -32000, message: "Directory creation error: \(error.localizedDescription)")
            return
        }
        
        do {
            try content.write(toFile: sanitizedPath, atomically: true, encoding: .utf8)
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": "Successfully wrote \(content.count) characters to \(sanitizedPath)"
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
        } catch {
            sendError(id: request.id, code: -32000, message: "File write error: \(error.localizedDescription)")
        }
    }
    
    private func handleListDirectory(request: JSONRPCRequest, arguments: [String: AnyCodable]) async {
        let pathString = arguments["path"]?.value as? String ?? FileManager.default.currentDirectoryPath
        
        guard let sanitizedPath = securityManager.sanitizePath(pathString) else {
            sendError(id: request.id, code: -32602, message: "Security error: invalid path")
            return
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            sendError(id: request.id, code: -32602, message: "Security error: path not allowed")
            return
        }
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: sanitizedPath)
            var results: [[String: Any]] = []
            
            for item in items.sorted() {
                let itemPath = URL(fileURLWithPath: sanitizedPath).appendingPathComponent(item).path
                do {
                    let attributes = try FileManager.default.attributesOfItem(atPath: itemPath)
                    let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory
                    let size = attributes[.size] as? Int ?? 0
                    let modificationDate = attributes[.modificationDate] as? Date ?? Date()
                    
                    results.append([
                        "name": item,
                        "path": itemPath,
                        "type": isDirectory ? "directory" : "file",
                        "size": size,
                        "modified": ISO8601DateFormatter().string(from: modificationDate)
                    ])
                } catch {
                    // Skip items we can't read
                    continue
                }
            }
            
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": "Directory listing for \(sanitizedPath):\n\(formatDirectoryListing(results))"
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
        } catch {
            sendError(id: request.id, code: -32000, message: "Directory listing error: \(error.localizedDescription)")
        }
    }
    
    private func handleCreateDirectory(request: JSONRPCRequest, arguments: [String: AnyCodable]) async {
        guard let pathString = arguments["path"]?.value as? String else {
            sendError(id: request.id, code: -32602, message: "Invalid parameters: missing path")
            return
        }
        
        guard let sanitizedPath = securityManager.sanitizePath(pathString) else {
            sendError(id: request.id, code: -32602, message: "Security error: invalid path")
            return
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            sendError(id: request.id, code: -32602, message: "Security error: path not allowed")
            return
        }
        
        do {
            try FileManager.default.createDirectory(atPath: sanitizedPath, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: nil)
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": "Successfully created directory: \(sanitizedPath)"
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
        } catch {
            sendError(id: request.id, code: -32000, message: "Directory creation error: \(error.localizedDescription)")
        }
    }
    
    private func handleGetFileInfo(request: JSONRPCRequest, arguments: [String: AnyCodable]) async {
        guard let pathString = arguments["path"]?.value as? String else {
            sendError(id: request.id, code: -32602, message: "Invalid parameters: missing path")
            return
        }
        
        guard let sanitizedPath = securityManager.sanitizePath(pathString) else {
            sendError(id: request.id, code: -32602, message: "Security error: invalid path")
            return
        }
        
        guard securityManager.isPathAllowed(sanitizedPath) else {
            sendError(id: request.id, code: -32602, message: "Security error: path not allowed")
            return
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: sanitizedPath)
            let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory
            let size = attributes[.size] as? Int ?? 0
            let creationDate = attributes[.creationDate] as? Date ?? Date()
            let modificationDate = attributes[.modificationDate] as? Date ?? Date()
            let permissions = attributes[.posixPermissions] as? Int ?? 0
            
            let info = """
                Path: \(sanitizedPath)
                Type: \(isDirectory ? "Directory" : "File")
                Size: \(formatFileSize(size))
                Created: \(ISO8601DateFormatter().string(from: creationDate))
                Modified: \(ISO8601DateFormatter().string(from: modificationDate))
                Permissions: \(String(permissions, radix: 8))
                """
            
            let result: [String: Any] = [
                "content": [
                    [
                        "type": "text",
                        "text": info
                    ]
                ]
            ]
            sendResult(id: request.id, result: result)
        } catch {
            sendError(id: request.id, code: -32000, message: "File info error: \(error.localizedDescription)")
        }
    }
    
    private func handleSearchFiles(request: JSONRPCRequest, arguments: [String: AnyCodable]) async {
        guard let pattern = arguments["pattern"]?.value as? String else {
            sendError(id: request.id, code: -32602, message: "Invalid parameters: missing pattern")
            return
        }
        
        let directoryString = arguments["directory"]?.value as? String ?? FileManager.default.currentDirectoryPath
        let recursive = arguments["recursive"]?.value as? Bool ?? false
        
        guard let sanitizedDirectory = securityManager.sanitizePath(directoryString) else {
            sendError(id: request.id, code: -32602, message: "Security error: invalid directory path")
            return
        }
        
        guard securityManager.isPathAllowed(sanitizedDirectory) else {
            sendError(id: request.id, code: -32602, message: "Security error: directory path not allowed")
            return
        }
        
        var matchingFiles: [String] = []
        
        func searchInDirectory(_ dir: String, depth: Int = 0) {
            guard depth < 5 else { return } // Prevent deep recursion
            
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: dir)
                for item in items {
                    let itemPath = URL(fileURLWithPath: dir).appendingPathComponent(item).path
                    
                    // Check if item matches pattern
                    if item.matches(pattern: pattern) {
                        matchingFiles.append(itemPath)
                    }
                    
                    // If recursive and item is directory, search it too
                    if recursive {
                        var isDir: ObjCBool = false
                        if FileManager.default.fileExists(atPath: itemPath, isDirectory: &isDir) && isDir.boolValue {
                            searchInDirectory(itemPath, depth: depth + 1)
                        }
                    }
                }
            } catch {
                // Skip directories we can't read
            }
        }
        
        searchInDirectory(sanitizedDirectory)
        
        let resultText = matchingFiles.isEmpty ? 
            "No files found matching pattern '\(pattern)' in \(sanitizedDirectory)" :
            "Found \(matchingFiles.count) files matching '\(pattern)':\n" + matchingFiles.joined(separator: "\n")
        
        let result: [String: Any] = [
            "content": [
                [
                    "type": "text",
                    "text": resultText
                ]
            ]
        ]
        sendResult(id: request.id, result: result)
    }
    
    // MARK: - Helper Methods
    
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
    
    private func formatDirectoryListing(_ items: [[String: Any]]) -> String {
        return items.map { item in
            let name = item["name"] as? String ?? ""
            let type = item["type"] as? String ?? ""
            let size = item["size"] as? Int ?? 0
            let typeIndicator = type == "directory" ? "📁" : "📄"
            let sizeString = type == "directory" ? "" : " (\(formatFileSize(size)))"
            return "\(typeIndicator) \(name)\(sizeString)"
        }.joined(separator: "\n")
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

// MARK: - Extensions

extension String {
    func matches(pattern: String) -> Bool {
        // Simple wildcard matching (* and ?)
        let regex = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")
        
        do {
            let nsRegex = try NSRegularExpression(pattern: "^" + regex + "$", options: [.caseInsensitive])
            let range = NSRange(location: 0, length: self.count)
            return nsRegex.firstMatch(in: self, options: [], range: range) != nil
        } catch {
            // If regex fails, fall back to simple contains check
            return self.lowercased().contains(pattern.lowercased())
        }
    }
}