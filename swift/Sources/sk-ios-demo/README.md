# iOS Semantic Kernel Demo

A basic iOS chat application demonstrating Semantic Kernel integration with SwiftUI.

## Features

- **Chat Interface**: Native iOS chat UI with message bubbles and typing indicators
- **Semantic Kernel Integration**: Uses SK Core with OpenAI connector
- **Built-in Plugins**: Includes Math, Text, and Time plugins
- **Responsive Design**: Optimized for iOS with proper keyboard handling

## Architecture

The app follows the MVVM pattern:

- `App.swift` - Main app entry point
- `ContentView.swift` - Main chat interface
- `ChatViewModel.swift` - Chat state management and SK integration
- `MessageBubble.swift` - Individual message display component
- `MessageInputView.swift` - Text input and send functionality
- `TypingIndicator.swift` - Animated typing indicator

## Setup

1. Ensure you have an OpenAI API key
2. Set the environment variable: `export OPENAI_API_KEY="your_key_here"`
3. Build and run: `swift build --product sk-ios-demo`

## Usage

The app initializes with Semantic Kernel and demonstrates:
- Basic chat functionality
- Plugin integration (Math, Text, Time)
- Error handling and status management
- iOS-specific UI patterns

## Dependencies

- SemanticKernelCore
- SemanticKernelConnectorsOpenAI
- SemanticKernelPluginsCore

Note: This is a basic demo. For production use, consider adding:
- Persistent chat history
- More sophisticated prompt engineering
- Enhanced error handling
- Additional plugins and capabilities