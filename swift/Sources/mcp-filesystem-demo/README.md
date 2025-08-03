# MCP Filesystem Demo

A macOS SwiftUI application demonstrating Model Context Protocol (MCP) filesystem operations integrated with Swift Semantic Kernel.

## Overview

This demo application showcases:

- **MCP Filesystem Operations**: Secure file and directory operations using the Model Context Protocol
- **SwiftUI Interface**: Modern macOS app with dual-pane layout
- **Semantic Kernel Integration**: AI-powered assistant for filesystem tasks
- **Security**: Path-based access control with allowlist management

## Features

### File Browser
- Interactive directory navigation
- File and folder listing with metadata
- Create new directories
- File selection and preview

### MCP Operations
- **List Directory**: Browse directory contents
- **Read File**: View file contents (up to 10MB)
- **Write File**: Create or modify files
- **Create Directory**: Make new folders
- **Get File Info**: Detailed file/directory information
- **Search Files**: Find files by pattern with wildcard support

### AI Assistant
- Context-aware filesystem assistance
- Integration with Semantic Kernel
- Chat interface for file operations

## Architecture

### Components

- **MCPShared**: Reusable MCP protocol types and filesystem service
- **MCPFilesystemService**: Core filesystem operations with security controls
- **MCPFilesystemViewModel**: SwiftUI view model managing app state
- **FileBrowserView**: Interactive file system browser
- **MCPOperationsView**: Interface for testing MCP operations
- **AIAssistantView**: Chat interface with AI integration

### Security Features

- **Path Allowlisting**: Operations restricted to safe directories
- **File Size Limits**: 10MB maximum file size
- **Directory Depth Limits**: Prevents deep recursion attacks  
- **Path Sanitization**: Removes dangerous path sequences

## Building and Running

### Prerequisites

- macOS 12.0+
- Xcode 14.0+
- Swift 5.7+

### Build

```bash
# Build the demo app
swift build --product mcp-filesystem-demo

# Run the demo app
swift run mcp-filesystem-demo
```

### Optional: AI Features

To enable full AI assistant features, set your OpenAI API key:

```bash
export OPENAI_API_KEY="your_openai_api_key_here"
swift run mcp-filesystem-demo
```

## Usage

1. **Browse Files**: Use the left panel to navigate your filesystem
2. **Test MCP Operations**: Use the "MCP Operations" tab to test individual operations
3. **AI Assistant**: Use the "AI Assistant" tab to interact with filesystem via natural language

### Allowed Directories

By default, the app has access to:
- Current working directory
- Documents folder
- Desktop folder
- Temporary directory

## Code Structure

```
Sources/mcp-filesystem-demo/
├── MCPFilesystemDemoApp.swift      # App entry point
├── ContentView.swift               # Main UI layout
├── FileBrowserView.swift           # File system browser
├── MCPOperationsView.swift         # MCP operations interface
├── AIAssistantView.swift           # AI chat interface
├── MCPFilesystemViewModel.swift    # View model and business logic
└── README.md                       # This file

Sources/MCPShared/
├── MCPProtocol.swift              # MCP protocol types
└── MCPFilesystemService.swift     # Filesystem operations
```

## MCP Protocol Implementation

The app implements a subset of the Model Context Protocol specification:

- **JSON-RPC 2.0**: Standard request/response protocol
- **Tool Definitions**: Schema-based operation definitions
- **Security Controls**: Path validation and access controls
- **Error Handling**: Comprehensive error reporting

## Development Notes

### Extending the Demo

To add new MCP operations:

1. Add tool definition to `MCPFilesystemTools` in `MCPProtocol.swift`
2. Implement operation in `MCPFilesystemService.swift`
3. Add UI handling in `MCPOperationsView.swift`
4. Update view model in `MCPFilesystemViewModel.swift`

### AI Integration

The current AI integration uses a placeholder response. To implement full Semantic Kernel integration:

1. Configure proper OpenAI service in `setupSemanticKernel()`
2. Implement conversation management in `getAIResponse()`
3. Add function calling capabilities for MCP operations
4. Consider using `FunctionCallingStepwisePlanner` for complex tasks

## Related Examples

- `hello-mcp-server`: Basic MCP server implementation
- `filesystem-mcp-server-basic`: Command-line MCP filesystem server
- `sk-samples-cli`: Interactive Semantic Kernel chat agent

## License

This demo is part of the Swift Semantic Kernel project.