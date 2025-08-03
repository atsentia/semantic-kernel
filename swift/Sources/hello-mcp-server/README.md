# Hello MCP Server

A simple Model Context Protocol (MCP) server implementation in Swift that demonstrates basic MCP protocol features following the JSON-RPC 2.0 specification.

## Overview

This server provides a minimal but complete MCP implementation that can be used as a starting point for building more complex MCP servers. It demonstrates:

- Proper JSON-RPC 2.0 message handling
- MCP protocol initialization
- Tool registration and execution
- Error handling and response formatting

## Available Tools

### hello
Returns a friendly greeting message.
- **Parameters:**
  - `name` (optional): Name to greet (defaults to "World")
- **Example:** `{"name": "Alice"}` → "Hello, Alice! 👋"

### echo  
Echoes back the provided message.
- **Parameters:**
  - `message` (required): Message to echo back
- **Example:** `{"message": "Test"}` → "Echo: Test"

### add
Adds two numbers together.
- **Parameters:**
  - `a` (required): First number
  - `b` (required): Second number  
- **Example:** `{"a": 5, "b": 3}` → "5.0 + 3.0 = 8.0"

### get_time
Returns the current date and time.
- **Parameters:** None
- **Example:** Returns current timestamp in full format

## Usage

### Building
```bash
swift build --product hello-mcp-server
```

### Running
```bash
swift run hello-mcp-server
```

The server reads JSON-RPC messages from stdin and writes responses to stdout. Log messages are written to stderr.

### End-to-End Communication Flow

The MCP server follows a complete request-response cycle for each operation. Here's how to interact with it:

#### 1. Server Startup
Start the server process:
```bash
swift run hello-mcp-server
```
The server will:
- Listen on stdin for JSON-RPC messages
- Send responses to stdout
- Log debug information to stderr

#### 2. Initialize Connection

**Client sends:**
```json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {}}}
```

**Server responds:**
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2024-11-05",
    "capabilities": {
      "tools": {}
    },
    "serverInfo": {
      "name": "hello-mcp-server",
      "version": "1.0.0"
    }
  }
}
```

#### 3. Discover Available Tools

**Client sends:**
```json
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
```

**Server responds:**
```json
{
  "jsonrpc": "2.0",
  "id": 2,
  "result": {
    "tools": [
      {
        "name": "hello",
        "description": "Returns a friendly greeting",
        "inputSchema": {
          "type": "object",
          "properties": {
            "name": {"type": "string", "description": "Name to greet"}
          }
        }
      },
      {
        "name": "echo",
        "description": "Echoes back a message",
        "inputSchema": {
          "type": "object",
          "properties": {
            "message": {"type": "string", "description": "Message to echo"}
          },
          "required": ["message"]
        }
      },
      {
        "name": "add",
        "description": "Adds two numbers",
        "inputSchema": {
          "type": "object",
          "properties": {
            "a": {"type": "number", "description": "First number"},
            "b": {"type": "number", "description": "Second number"}
          },
          "required": ["a", "b"]
        }
      },
      {
        "name": "get_time",
        "description": "Returns current time",
        "inputSchema": {
          "type": "object",
          "properties": {}
        }
      }
    ]
  }
}
```

#### 4. Execute Tools

**Example 1 - Hello tool with parameter:**
```json
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "hello", "arguments": {"name": "Alice"}}}
```
**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 3,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Hello, Alice! 👋"
      }
    ]
  }
}
```

**Example 2 - Add tool with numbers:**
```json
{"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": "add", "arguments": {"a": 15, "b": 27}}}
```
**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 4,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "15.0 + 27.0 = 42.0"
      }
    ]
  }
}
```

**Example 3 - Error handling for missing required parameter:**
```json
{"jsonrpc": "2.0", "id": 5, "method": "tools/call", "params": {"name": "echo", "arguments": {}}}
```
**Response:**
```json
{
  "jsonrpc": "2.0",
  "id": 5,
  "error": {
    "code": -32602,
    "message": "Invalid params",
    "data": "Missing required parameter: message"
  }
}
```

#### 5. Interactive Testing

You can test the server interactively by piping JSON messages:

```bash
# Start the server
swift run hello-mcp-server

# In another terminal, send a message:
echo '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {}}}' | swift run hello-mcp-server

# Or use a simple test script:
echo '{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "hello", "arguments": {"name": "World"}}}' | swift run hello-mcp-server
```

#### Message Flow Summary
1. **Startup**: Server begins listening on stdin
2. **Initialize**: Handshake establishes protocol version and capabilities
3. **Discovery**: Client lists available tools and their schemas
4. **Execution**: Client calls tools with parameters, server responds with results
5. **Error Handling**: Server returns structured errors for invalid requests
6. **Cleanup**: Process terminates when stdin closes

## Protocol Support

This server implements:
- ✅ MCP Protocol Version: 2024-11-05
- ✅ JSON-RPC 2.0 specification
- ✅ Tool capabilities
- ✅ Initialization handshake
- ✅ Error handling
- ✅ Proper response formatting

## Architecture

The server is built with a clean, modular architecture:

- **JSONRPCRequest/Response**: Protocol message structures
- **AnyCodable**: Type-erased wrapper for flexible JSON handling
- **HelloMCPServer**: Main server implementation with tool handlers
- **Tool handlers**: Individual functions for each tool implementation

This design makes it easy to add new tools or extend functionality while maintaining protocol compliance.

## Security

This example server is designed for demonstration and development use. For production use, consider:
- Input validation and sanitization
- Rate limiting
- Authentication/authorization
- Resource usage limits
- Comprehensive error handling

## MCP Specification

This server follows the Model Context Protocol specification available at:
https://modelcontextprotocol.io/specification