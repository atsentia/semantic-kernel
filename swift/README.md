# Swift Semantic Kernel

A Swift implementation of [Semantic Kernel](https://github.com/microsoft/semantic-kernel) - an SDK that integrates Large Language Models (LLMs) with conventional programming languages, enabling AI-powered applications with a clean architecture.

## 🚀 Quick Start

### Requirements
- Swift 5.9+
- macOS 13.0+ / iOS 16.0+ / visionOS 1.0+
- Xcode 15.0+ (for iOS/visionOS development)

### Installation

#### Swift Package Manager
Add to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/microsoft/swift-semantic-kernel.git", from: "1.0.0")
]
```

#### Environment Setup
Create a `.env` file in your project root:
```bash
OPENAI_API_KEY="your_openai_api_key_here"
# Optional: For Azure OpenAI
AZURE_OPENAI_API_KEY="your_azure_key"
AZURE_OPENAI_ENDPOINT="your_azure_endpoint"
```

### Basic Example
```swift
import SemanticKernel
import SemanticKernelOpenAI
import SemanticKernelPlugins

// Create and configure kernel
var builder = KernelBuilder()
builder = await builder
    .withService(OpenAIChatCompletionService(apiKey: "your-key", model: "gpt-4"))
    .withPlugin(MathPlugin())
    .withPlugin(TimePlugin())

let kernel = await builder.build()

// Use natural language to invoke functions
let result = try await kernel.chatCompletion.process(
    prompt: "What is 15 + 27?",
    kernel: kernel
)
print(result) // "The sum of 15 and 27 is 42"
```

## 📱 Platform Support

### iOS/macOS Applications
```swift
import SwiftUI
import SemanticKernel
import SemanticKernelOpenAI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var kernel: Kernel?
    
    func initialize() async {
        var builder = KernelBuilder()
        builder = await builder
            .withService(OpenAIChatCompletionService(
                apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
                model: "gpt-4"
            ))
            .withPlugin(TextPlugin())
            .withPlugin(TimePlugin())
        
        kernel = await builder.build()
    }
    
    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        guard let kernel = kernel else { return }
        
        let response = try? await kernel.chatCompletion.process(
            prompt: text,
            kernel: kernel
        )
        
        if let response = response {
            messages.append(ChatMessage(content: response, isUser: false))
        }
    }
}
```

### visionOS Support
Full support for Apple Vision Pro with spatial computing features:
```bash
# Run visionOS demo
swift run SemanticKernelVisionOS

# Or open in Xcode
open SemanticKernelVisionOS/SemanticKernelVisionOS.xcodeproj
```

## 🏗️ Architecture

### Core Components

| Component | Description |
|-----------|-------------|
| **SemanticKernel** | Main library bundle (includes all core components) |
| **SemanticKernelAbstractions** | Protocol definitions and base types |
| **SemanticKernelCore** | Kernel implementation, orchestration, memory management |
| **SemanticKernelSupport** | Helper utilities and extensions |

### Service Connectors

| Connector | Description | Status |
|-----------|-------------|---------|
| **SemanticKernelOpenAI** | OpenAI/ChatGPT integration | ✅ Production |
| **SemanticKernelAzureOpenAI** | Azure OpenAI Service | 🚧 In Development |
| **SemanticKernelQdrant** | Qdrant vector database | ✅ Production |

### Built-in Plugins

| Plugin | Capabilities |
|--------|--------------|
| **MathPlugin** | Basic arithmetic operations |
| **TextPlugin** | String manipulation (uppercase, lowercase, trim, length) |
| **TimePlugin** | Date/time operations |
| **FileIOPlugin** | File system operations |
| **HttpPlugin** | HTTP requests |

## 🧪 Demo Applications

### Command Line Tools
```bash
# Interactive chat with AI and plugins
swift run sk-samples-cli

# Test all plugins with AI integration
swift run plugin-test

# Test function calling capabilities
swift run function-calling-test

# Performance benchmarking
swift run sk-bench
```

### GUI Applications
```bash
# iOS demo app (runs as macOS app)
swift run sk-ios-demo

# macOS MCP filesystem demo
swift run mcp-filesystem-demo

# visionOS demo
swift run SemanticKernelVisionOS
```

### MCP Server Examples
```bash
# Basic MCP server
swift run hello-mcp-server

# Filesystem server with security
swift run filesystem-mcp-server-basic

# With JWT authentication
swift run filesystem-mcp-server-jwt

# With OAuth 2.1 + PKCE
swift run filesystem-mcp-server-oauth
```

## 🔧 Advanced Features

### Function Calling
The kernel automatically detects when to call functions based on natural language:
```swift
// AI will automatically call the appropriate function
let result = try await kernel.chatCompletion.process(
    prompt: "What time is it in Tokyo?",
    kernel: kernel  // Has TimePlugin registered
)
```

### Semantic Memory
Store and retrieve information using vector embeddings:
```swift
// Configure memory store
builder = await builder
    .withMemoryStore(QdrantMemoryStore(url: "http://localhost:6333"))
    .withService(OpenAIEmbeddingService(apiKey: apiKey))

// Save memory
try await kernel.memory.save(
    collection: "facts",
    text: "The Swift programming language was introduced in 2014",
    id: "swift-intro"
)

// Search memories
let memories = try await kernel.memory.search(
    collection: "facts",
    query: "When was Swift created?",
    limit: 5
)
```

### Model Context Protocol (MCP)
Create AI-powered tools that integrate with other applications:
```swift
// See MCP.md for detailed implementation guide
let server = MCPServer()
server.registerTool("search_files", handler: searchFilesHandler)
server.registerTool("read_file", handler: readFileHandler)
try await server.start()
```

## 📊 Performance

- **Async/Await**: Full concurrency support with Swift's modern async APIs
- **Streaming**: Support for streaming responses to reduce latency
- **Caching**: Built-in response caching for improved performance
- **Error Handling**: Comprehensive error handling with retry logic

## 🛡️ Security

- **API Key Management**: Secure storage via environment variables
- **Sandboxed Execution**: Safe plugin execution environment
- **Input Validation**: Automatic sanitization of user inputs
- **Rate Limiting**: Built-in rate limiting for API calls

## 🧪 Testing

```bash
# Run all tests (Note: UI tests currently have Swift 6 concurrency issues)
swift test

# Run specific test suites
swift test --filter SemanticKernelCoreTests
swift test --filter OpenAIIntegrationTests

# Run with coverage
swift test --enable-code-coverage
```

## ✅ Build Status

All components build successfully with Swift 6.0:

| Component | Build Status | Notes |
|-----------|--------------|-------|
| Core Libraries | ✅ Success | All semantic kernel libraries compile without errors |
| Service Connectors | ✅ Success | OpenAI, Azure OpenAI, and Qdrant connectors build correctly |
| Plugins | ✅ Success | All built-in plugins compile successfully |
| MCP Servers | ✅ Success | All 4 MCP server variants build and run correctly |
| Demo Applications | ✅ Success | All CLI and GUI demos build successfully |
| Tests | ⚠️ Partial | Core tests pass, UI tests have Swift 6 @MainActor isolation issues |

### Verified MCP Functionality
- ✅ Protocol initialization and handshaking
- ✅ Tool listing and discovery
- ✅ Tool execution with proper argument handling
- ✅ Security controls (path allowlisting)
- ✅ JSON-RPC communication
- ✅ Error handling and validation

## 📚 Documentation

- [API Documentation](https://microsoft.github.io/swift-semantic-kernel/)
- [MCP Integration Guide](MCP.md)
- [Plugin Development Guide](docs/plugins.md)
- [Migration Guide](docs/migration.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md).

### Development Setup
```bash
# Clone the repository
git clone https://github.com/microsoft/swift-semantic-kernel.git
cd swift-semantic-kernel

# Build the project
swift build

# Run tests
swift test

# Generate documentation
swift package generate-documentation
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Acknowledgments

- Microsoft Semantic Kernel team for the original C# implementation
- OpenAI for their powerful language models
- The Swift community for their continuous support

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/microsoft/swift-semantic-kernel/issues)
- **Discussions**: [GitHub Discussions](https://github.com/microsoft/swift-semantic-kernel/discussions)
- **Stack Overflow**: Tag questions with `swift-semantic-kernel`