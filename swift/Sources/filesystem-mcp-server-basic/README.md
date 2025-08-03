# Filesystem MCP Server

A secure Model Context Protocol (MCP) server for filesystem operations with path-based access control and security best practices.

## Overview

This server provides secure filesystem access through the MCP protocol, implementing comprehensive security measures:

- **Path-based access control** with allowlist restrictions
- **File size limits** (10MB maximum)
- **Directory depth validation**
- **Path sanitization** to prevent directory traversal attacks
- **Comprehensive error handling**

## Security Features

### Access Control
The server uses an allowlist approach, restricting access to:
- Current working directory
- User's Documents directory
- User's Desktop directory
- System temporary directory

### Safety Measures
- **File size limit**: 10MB maximum to prevent resource exhaustion
- **Directory depth limit**: Maximum 10 levels deep
- **Path sanitization**: Removes `../` and other dangerous sequences
- **No system file access**: Critical system directories are blocked
- **Validation**: All operations validate paths before execution

## Available Tools

### read_file
Securely reads the contents of a text file.
- **Parameters:**
  - `path` (required): Path to the file to read
- **Security:** Path must be within allowed directories, file must be under 10MB
- **Example:** Read a document from your Desktop

### write_file
Securely writes content to a file with directory creation.
- **Parameters:**
  - `path` (required): Path to the file to write
  - `content` (required): Content to write to the file
- **Security:** Creates parent directories if needed, validates path access
- **Example:** Save content to a file in Documents

### list_directory
Lists contents of a directory with detailed file information.
- **Parameters:**
  - `path` (optional): Directory path (defaults to current directory)
- **Returns:** File names, types (file/directory), sizes, modification dates
- **Security:** Only lists allowed directories

### create_directory
Creates a new directory with parent directory creation.
- **Parameters:**
  - `path` (required): Path to the directory to create
- **Security:** Creates intermediate directories, validates path access
- **Example:** Create a new project folder

### get_file_info
Gets detailed information about a file or directory.
- **Parameters:**
  - `path` (required): Path to the file or directory
- **Returns:** Type, size, creation/modification dates, permissions
- **Security:** Only accesses files within allowed paths

### search_files
Searches for files by name pattern in a directory.
- **Parameters:**
  - `directory` (optional): Directory to search (defaults to current directory)
  - `pattern` (required): File name pattern with wildcards (*.txt, etc.)
  - `recursive` (optional): Whether to search subdirectories (defaults to false)
- **Security:** Limited recursion depth, only searches allowed directories
- **Example:** Find all Swift files: `{"pattern": "*.swift"}`

## Usage

### Building
```bash
swift build --product filesystem-mcp-server
```

### Running
```bash
swift run filesystem-mcp-server
```

### Example Operations

1. **Initialize the server:**
```json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {}}}
```

2. **List available tools:**
```json
{"jsonrpc": "2.0", "id": 2, "method": "tools/list"}
```

3. **Read a file:**
```json
{"jsonrpc": "2.0", "id": 3, "method": "tools/call", "params": {"name": "read_file", "arguments": {"path": "./README.md"}}}
```

4. **List current directory:**
```json
{"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": "list_directory", "arguments": {}}}
```

5. **Search for Swift files:**
```json
{"jsonrpc": "2.0", "id": 5, "method": "tools/call", "params": {"name": "search_files", "arguments": {"pattern": "*.swift"}}}
```

## Error Handling

The server provides detailed error messages for security violations:

- **Path not allowed**: When trying to access files outside allowed directories
- **File too large**: When trying to read files over 10MB
- **Invalid path**: When path contains dangerous sequences
- **File not found**: When target files don't exist
- **Permission denied**: When lacking filesystem permissions

## Protocol Support

This server implements:
- ✅ MCP Protocol Version: 2024-11-05
- ✅ JSON-RPC 2.0 specification
- ✅ Tool capabilities with secure execution
- ✅ Comprehensive error handling
- ✅ Input validation and sanitization
- ✅ Resource usage limits

## Configuration

By default, the server allows access to:

```
Current Directory: /path/to/current/directory
Documents: /Users/username/Documents
Desktop: /Users/username/Desktop  
Temp: /var/folders/.../T/
```

The security manager can be extended to add additional allowed paths if needed.

## Best Practices

When using this server:

1. **Run with minimal privileges** - Don't run as root/administrator
2. **Review allowed paths** - Ensure they match your security requirements
3. **Monitor file operations** - Check logs for security violations
4. **Update regularly** - Keep the server updated with security patches
5. **Validate inputs** - The server validates, but client-side validation is also good

## Architecture

The server follows a layered security architecture:

- **SecurityManager**: Handles path validation and access control
- **Tool Handlers**: Implement individual filesystem operations
- **Protocol Layer**: Manages MCP/JSON-RPC communication
- **Error Handling**: Provides detailed security error reporting

This design ensures that security is enforced at every level of the system.

## MCP Specification

This server follows the Model Context Protocol specification available at:
https://modelcontextprotocol.io/specification

## Security Considerations

This server is designed with security as a primary concern, but consider these additional measures for production use:

- **Network isolation**: Run in a sandboxed environment
- **Resource monitoring**: Monitor disk usage and file operations
- **Audit logging**: Log all file operations for security analysis
- **Regular security reviews**: Review and update security policies
- **User education**: Ensure users understand the security model