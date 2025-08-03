//
// MCP Filesystem View Model
// Handles file operations and state management for the demo app
//

import SwiftUI
import MCPShared
import SemanticKernelCore
import SemanticKernelConnectorsOpenAI

@MainActor
class MCPFilesystemViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var currentPath: String = ""
    @Published var selectedFile: FileItem?
    @Published var isLoading = false
    @Published var lastError: String?
    
    // MCP Operations
    @Published var mcpOperationResult: String = ""
    @Published var isPerformingOperation = false
    
    // AI Assistant
    @Published var chatMessages: [ChatMessage] = []
    @Published var isWaitingForAI = false
    @Published var userInput: String = ""
    
    private let filesystemService = MCPFilesystemService()
    private var pathHistory: [String] = []
    private var kernel: Kernel?
    
    var canNavigateUp: Bool {
        return pathHistory.count > 1
    }
    
    init() {
        currentPath = FileManager.default.currentDirectoryPath
        pathHistory.append(currentPath)
        setupSemanticKernel()
    }
    
    // MARK: - File Operations
    
    func loadInitialDirectory() {
        refreshCurrentDirectory()
    }
    
    func refreshCurrentDirectory() {
        isLoading = true
        lastError = nil
        
        Task {
            do {
                let fileItems = try filesystemService.listDirectory(path: currentPath)
                await MainActor.run {
                    self.files = fileItems
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    func navigateToDirectory(_ path: String) {
        currentPath = path
        pathHistory.append(path)
        refreshCurrentDirectory()
    }
    
    func navigateUp() {
        guard canNavigateUp else { return }
        
        pathHistory.removeLast()
        currentPath = pathHistory.last ?? FileManager.default.currentDirectoryPath
        refreshCurrentDirectory()
    }
    
    func selectFile(_ file: FileItem) {
        selectedFile = file
        
        if file.type == .file {
            // Load file content for preview
            Task {
                do {
                    let content = try filesystemService.readFile(path: file.path)
                    await MainActor.run {
                        // Could show file content in a preview pane
                        self.mcpOperationResult = "File: \(file.name)\nSize: \(filesystemService.formatFileSize(file.size))\n\nContent:\n\(content.prefix(500))\(content.count > 500 ? "..." : "")"
                    }
                } catch {
                    await MainActor.run {
                        self.lastError = error.localizedDescription
                    }
                }
            }
        }
    }
    
    func createDirectory(named name: String) {
        let newPath = URL(fileURLWithPath: currentPath).appendingPathComponent(name).path
        
        Task {
            do {
                try filesystemService.createDirectory(path: newPath)
                await MainActor.run {
                    self.refreshCurrentDirectory()
                }
            } catch {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - MCP Operations
    
    func performMCPOperation(_ operation: MCPOperation, parameters: [String: String] = [:]) {
        isPerformingOperation = true
        mcpOperationResult = ""
        
        Task {
            do {
                let result = try await executeMCPOperation(operation, parameters: parameters)
                await MainActor.run {
                    self.mcpOperationResult = result
                    self.isPerformingOperation = false
                    if operation == .listDirectory || operation == .createDirectory {
                        self.refreshCurrentDirectory()
                    }
                }
            } catch {
                await MainActor.run {
                    self.mcpOperationResult = "Error: \(error.localizedDescription)"
                    self.isPerformingOperation = false
                }
            }
        }
    }
    
    private func executeMCPOperation(_ operation: MCPOperation, parameters: [String: String]) async throws -> String {
        switch operation {
        case .listDirectory:
            let path = parameters["path"] ?? currentPath
            let items = try filesystemService.listDirectory(path: path)
            return formatDirectoryListing(items)
            
        case .readFile:
            guard let path = parameters["path"] else {
                throw MCPFilesystemError.invalidPath
            }
            return try filesystemService.readFile(path: path)
            
        case .writeFile:
            guard let path = parameters["path"],
                  let content = parameters["content"] else {
                throw MCPFilesystemError.invalidPath
            }
            try filesystemService.writeFile(path: path, content: content)
            return "Successfully wrote \(content.count) characters to \(path)"
            
        case .createDirectory:
            guard let path = parameters["path"] else {
                throw MCPFilesystemError.invalidPath
            }
            try filesystemService.createDirectory(path: path)
            return "Successfully created directory: \(path)"
            
        case .getFileInfo:
            guard let path = parameters["path"] else {
                throw MCPFilesystemError.invalidPath
            }
            let fileInfo = try filesystemService.getFileInfo(path: path)
            return formatFileInfo(fileInfo)
            
        case .searchFiles:
            let directory = parameters["directory"] ?? currentPath
            guard let pattern = parameters["pattern"] else {
                throw MCPFilesystemError.invalidPath
            }
            let recursive = parameters["recursive"] == "true"
            let results = try filesystemService.searchFiles(directory: directory, pattern: pattern, recursive: recursive)
            
            if results.isEmpty {
                return "No files found matching pattern '\(pattern)' in \(directory)"
            } else {
                return "Found \(results.count) files matching '\(pattern)':\n" + results.map { $0.path }.joined(separator: "\n")
            }
        }
    }
    
    private func formatDirectoryListing(_ items: [FileItem]) -> String {
        return items.map { item in
            let sizeString = item.type == .directory ? "" : " (\(filesystemService.formatFileSize(item.size)))"
            return "\(item.type.icon) \(item.name)\(sizeString)"
        }.joined(separator: "\n")
    }
    
    private func formatFileInfo(_ file: FileItem) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
        
        return """
        Path: \(file.path)
        Type: \(file.type == .directory ? "Directory" : "File")
        Size: \(filesystemService.formatFileSize(file.size))
        Modified: \(formatter.string(from: file.modified))
        """
    }
    
    // MARK: - AI Assistant
    
    private func setupSemanticKernel() {
        // This would be configured with your OpenAI API key
        // For demo purposes, we'll leave it as optional
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            return
        }
        
        Task {
            do {
                var builder = KernelBuilder()
                // Temporarily disable Semantic Kernel integration for demo
                // let chatService = OpenAIChatCompletionService(apiKey: apiKey, model: "gpt-4")
                // builder = await builder.withService(chatService)
                let builtKernel = await builder.build()
                await MainActor.run {
                    self.kernel = builtKernel
                }
            } catch {
                print("Failed to initialize Semantic Kernel: \(error)")
            }
        }
    }
    
    func sendMessage(_ message: String) {
        guard !message.isEmpty else { return }
        
        let userMessage = ChatMessage(content: message, isFromUser: true)
        chatMessages.append(userMessage)
        userInput = ""
        isWaitingForAI = true
        
        Task {
            do {
                let response = try await getAIResponse(for: message)
                await MainActor.run {
                    let aiMessage = ChatMessage(content: response, isFromUser: false)
                    self.chatMessages.append(aiMessage)
                    self.isWaitingForAI = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(content: "Error: \(error.localizedDescription)", isFromUser: false)
                    self.chatMessages.append(errorMessage)
                    self.isWaitingForAI = false
                }
            }
        }
    }
    
    private func getAIResponse(for message: String) async throws -> String {
        guard let kernel = kernel else {
            return "AI Assistant is not configured. Please set your OPENAI_API_KEY environment variable."
        }
        
        // Create a context-aware prompt that includes current directory info
        let contextPrompt = """
        You are an AI assistant helping with filesystem operations. The user is currently in directory: \(currentPath)
        
        Available files and directories:
        \(formatDirectoryListing(files))
        
        You can help with:
        - File and directory operations
        - Explaining filesystem concepts
        - Suggesting file organization strategies
        - Code analysis if files contain code
        
        User question: \(message)
        
        Provide a helpful response based on the current filesystem context.
        """
        
        // This is a simplified example - in a real implementation you might use
        // more sophisticated prompt engineering and function calling
        return try await kernel.invokePrompt(contextPrompt)
    }
}

// MARK: - Supporting Types

enum MCPOperation: String, CaseIterable {
    case listDirectory = "list_directory"
    case readFile = "read_file"
    case writeFile = "write_file"
    case createDirectory = "create_directory"
    case getFileInfo = "get_file_info"
    case searchFiles = "search_files"
    
    var displayName: String {
        switch self {
        case .listDirectory: return "List Directory"
        case .readFile: return "Read File"
        case .writeFile: return "Write File"
        case .createDirectory: return "Create Directory"
        case .getFileInfo: return "Get File Info"
        case .searchFiles: return "Search Files"
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp = Date()
}

// MARK: - Kernel Extension

extension Kernel {
    func invokePrompt(_ prompt: String) async throws -> String {
        // Use a simple prompt invocation for the chat
        // In a more sophisticated implementation, you might use the planner
        // or more complex conversation management
        
        // For demo purposes, return a context-aware response
        // In a production app, you would integrate with the actual Semantic Kernel chat completion
        return "AI Assistant: I can help you with filesystem operations. What would you like to know or do with your files? (Note: Full AI integration requires OpenAI API key configuration)"
    }
}