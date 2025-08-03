# Swift Semantic Kernel

A Swift implementation of [Semantic Kernel](https://github.com/microsoft/semantic-kernel) - an SDK that integrates Large Language Models (LLMs) with conventional programming languages.

## 🚀 Quick Start & Demos

### Environment Setup
Create a `.env` file in the project root:
```bash
OPENAI_API_KEY="your_openai_api_key_here"
```

### Try the Demos
```bash
# Build the project
swift build

# 🧪 Test all plugins (Math, Text, Time) with AI integration
swift run plugin-test

# 🤖 Test ChatAgent with function calling
swift run chatagent-test

# ⚡ Test function calling approaches
swift run function-calling-test

# 🔧 Test API integration
swift run api-test

# 💬 Interactive chat agent (type 'exit' to quit)
swift run sk-samples-cli

# 📱 iOS demo app (runs as macOS app)
swift run sk-ios-demo

# 📁 macOS MCP filesystem demo
swift run mcp-filesystem-demo
```

### Demo Results
✅ **Math Plugin**: `"What is 15 + 27?"` → `"The sum of 15 and 27 is 42"`  
✅ **Text Plugin**: Uppercase conversion, length counting  
✅ **Time Plugin**: Current time and date retrieval  
✅ **Function Calling**: AI automatically calls Swift functions  
✅ **Natural Language**: Ask questions in plain English, get function-based responses

## 🏗️ Architecture

### 📚 Core Libraries
```swift
import SemanticKernel  // Main library (recommended)
```

| Library | Purpose |
|---------|---------|
| **SemanticKernel** | Main library (includes Core + Abstractions + Support) |
| **SemanticKernelAbstractions** | Protocol definitions and base types |
| **SemanticKernelCore** | Kernel implementation, planning, memory |
| **SemanticKernelSupport** | Helper utilities |

### 🔌 Service Connectors
| Connector | Purpose |
|-----------|---------|
| **SemanticKernelOpenAI** | OpenAI/ChatGPT integration |
| **SemanticKernelAzureOpenAI** | Azure OpenAI integration |  
| **SemanticKernelQdrant** | Qdrant vector database |

### 🧩 Plugins & Extensions
| Component | Purpose |
|-----------|---------|
| **SemanticKernelPlugins** | Built-in plugins (Math, Text, Time, FileIO, Http) |
| **SemanticKernelMCP** | Model Context Protocol support |

## 💻 Basic Usage

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

// Use the kernel
let result = try await kernel.run(
    functionName: "getCurrentTime", 
    inPlugin: "TimePlugin"
)
print(result.output)
```

### iOS App Integration
```swift
import SwiftUI
import SemanticKernel
import SemanticKernelOpenAI

struct ChatView: View {
    @StateObject private var chatService = ChatService()
    
    var body: some View {
        // Your SwiftUI chat interface
    }
}

class ChatService: ObservableObject {
    private var kernel: Kernel?
    
    func initializeKernel() async {
        var builder = KernelBuilder()
        builder = await builder.withService(
            OpenAIChatCompletionService(apiKey: apiKey, model: "gpt-4")
        )
        kernel = await builder.build()
    }
}
```

## 📱 Available Demos

### Interactive Applications
- **`sk-samples-cli`** - Interactive command-line chat agent  
- **`sk-ios-demo`** - iOS SwiftUI chat app (runs as macOS app)
- **`mcp-filesystem-demo`** - macOS app with MCP filesystem operations

### Testing & Development Tools
- **`plugin-test`** - Test Math, Text, Time plugins with AI integration
- **`chatagent-test`** - Test ChatAgent with function calling
- **`function-calling-test`** - Test different function calling approaches
- **`api-test`** - Test OpenAI API integration
- **`sk-bench`** - Performance benchmarking tool
- **`openai-api-call`** - Simple OpenAI API usage example

### MCP Server Examples  
- **`hello-mcp-server`** - Basic MCP server implementation
- **`filesystem-mcp-server-basic`** - Secure filesystem MCP server
- **`filesystem-mcp-server-jwt`** - MCP server with JWT authentication
- **`filesystem-mcp-server-oauth`** - MCP server with OAuth 2.1 + PKCE

## 🛠️ Development

### Building & Testing
```bash
# Build all targets
swift build

# Build specific executable
swift build --product sk-samples-cli

# Run all tests
swift test

# Run specific test suite
swift test --filter SemanticKernelCoreTests
```

### iOS Application
```bash
# Build and run iOS demo in simulator (without Xcode)
./run-ios-demo.sh

# Alternative: Build as macOS app
swift run sk-ios-demo
```

## 📦 Using in Your Project

### Swift Package Manager
Add to your `Package.swift`:
```swift
dependencies: [
    .package(url: "https://github.com/microsoft/swift-semantic-kernel.git", from: "1.0.0")
]
```

Then import what you need:
```swift
// For basic usage
import SemanticKernel
import SemanticKernelOpenAI

// For advanced scenarios  
import SemanticKernelCore
import SemanticKernelPlugins
import SemanticKernelMCP
```

## ✨ Key Features

✅ **OpenAI Integration** - Full ChatGPT/GPT-4 support with function calling  
✅ **Plugin System** - Math, Text, Time, FileIO, Http plugins  
✅ **Natural Language** - Ask questions, get function-based responses  
✅ **iOS/macOS Support** - Native SwiftUI integration  
✅ **MCP Protocol** - Model Context Protocol server implementations  
✅ **Production Ready** - Clean architecture, comprehensive testing

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.