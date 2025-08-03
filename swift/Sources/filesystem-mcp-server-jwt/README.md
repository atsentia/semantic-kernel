# Filesystem MCP Server with JWT Authentication

A secure Model Context Protocol (MCP) server for filesystem operations with JWT + API Key authentication and comprehensive authorization.

## Overview

This server extends the basic filesystem MCP server with enterprise-grade authentication and authorization features:

- **JWT token authentication** with custom claims
- **API Key authentication** with user permissions  
- **Rate limiting** to prevent abuse
- **Scope-based authorization** (filesystem:read, filesystem:write)
- **User permission system** with path restrictions
- **Secure HMAC-SHA256 JWT signing**

## Authentication Methods

### 1. API Key Authentication
Authenticate with a pre-configured API key to receive a JWT token for the session.

**Configuration:**
```swift
// Default demo API key (change in production)
"demo-api-key": UserPermissions(
    userId: "demo-user",
    scopes: ["filesystem:read", "filesystem:write"],
    allowedPaths: nil, // Uses default security manager paths
    maxFileSize: nil,  // Uses default 10MB limit
    canWrite: true,
    canDelete: false
)
```

### 2. JWT Token Authentication  
Use a valid JWT token for authenticated requests.

**JWT Claims:**
- `userId`: User identifier
- `scopes`: Array of permission scopes
- `allowedPaths`: Optional path restrictions
- `maxFileSize`: Optional file size limits
- `canWrite`: Write permission flag
- `canDelete`: Delete permission flag
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp

## Security Features

### Authentication
- **HMAC-SHA256** JWT signing and verification
- **Token expiration** (1 hour default)
- **API key validation** against configured allowlist
- **Session-based tokens** generated from API keys

### Authorization  
- **Scope-based permissions** (read/write separation)
- **Path-based access control** (per-user restrictions)
- **File size limits** (configurable per user)
- **Operation-specific permissions** (read/write/delete)

### Rate Limiting
- **Requests per minute**: 60 (configurable)
- **Requests per hour**: 1000 (configurable)
- **Per-API-key tracking** with automatic cleanup
- **Memory-efficient** old request cleanup

## Available Tools

All tools from the basic filesystem server plus authentication:

### read_file
- **Requires:** `filesystem:read` scope
- **Authorization:** Validates path access for user
- **Security:** All basic filesystem security plus auth

### write_file  
- **Requires:** `filesystem:write` scope + `canWrite: true`
- **Authorization:** Validates path access and file size limits
- **Security:** Content size checked against user limits

### list_directory
- **Requires:** `filesystem:read` scope
- **Authorization:** Directory must be in user's allowed paths

### create_directory
- **Requires:** `filesystem:write` scope + `canWrite: true`  
- **Authorization:** Path must be within user's allowed directories

### get_file_info
- **Requires:** `filesystem:read` scope
- **Authorization:** File path must be accessible to user

### search_files
- **Requires:** `filesystem:read` scope
- **Authorization:** Search directory must be in allowed paths

## Environment Variables

### Required
- `MCP_JWT_SECRET`: Secret key for JWT signing (change from default!)

### Optional  
- Configure API keys and permissions in `AuthConfig.default`
- Customize rate limiting in `RateLimitConfig`

## Usage

### Building
```bash
swift build --product filesystem-mcp-server-jwt
```

### Running
```bash
# Set JWT secret (required for security)
export MCP_JWT_SECRET="your-secure-secret-key-here"
swift run filesystem-mcp-server-jwt
```

### Authentication Flow

1. **Initialize the server:**
```json
{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {}}}
```

2. **Authenticate with API key** (in tool call metadata):
```json
{
  "jsonrpc": "2.0", 
  "id": 2, 
  "method": "tools/call", 
  "params": {
    "name": "read_file",
    "arguments": {"path": "./test.txt"},
    "_auth": {"api_key": "demo-api-key"}
  }
}
```

3. **Authenticate with JWT** (in tool call metadata):
```json
{
  "jsonrpc": "2.0",
  "id": 3, 
  "method": "tools/call",
  "params": {
    "name": "write_file", 
    "arguments": {"path": "./output.txt", "content": "Hello World"},
    "_auth": {"jwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."}
  }
}
```

## Error Codes

The server uses specific JSON-RPC error codes for authentication:

- **-32001**: Unauthorized (invalid credentials, expired token)
- **-32002**: Forbidden (insufficient permissions, path not allowed)  
- **-32003**: Rate Limited (too many requests)
- **-32004**: Internal Error (token generation failed)

## Production Configuration

### Security Checklist
- [ ] Change default JWT secret
- [ ] Replace demo API keys with production keys
- [ ] Configure appropriate rate limits
- [ ] Set user-specific path restrictions
- [ ] Enable audit logging
- [ ] Run with minimal system privileges

### Example Production Config
```swift
let productionConfig = AuthConfig(
    jwtSecret: ProcessInfo.processInfo.environment["MCP_JWT_SECRET"]!,
    tokenExpiration: 1800, // 30 minutes
    allowedAPIKeys: [
        "prod-user-1-key": UserPermissions(
            userId: "user-1",
            scopes: ["filesystem:read"],
            allowedPaths: ["/home/user1/workspace"],
            maxFileSize: 5_000_000, // 5MB
            canWrite: false,
            canDelete: false
        )
    ],
    rateLimiting: RateLimitConfig(
        requestsPerMinute: 30,
        requestsPerHour: 500
    )
)
```

## Status

✅ **Working** - All compilation errors have been fixed:
- ~~`@main` attribute conflict with top-level code~~ - Fixed using Task-based execution
- ~~Module structure needs refactoring~~ - Fixed with proper async execution pattern

## Architecture

### Core Components
- **AuthManager**: JWT generation, validation, and API key management
- **AuthConfig**: Configuration for authentication settings
- **UserPermissions**: Per-user permission and restriction settings
- **RateLimitConfig**: Rate limiting configuration
- **JWT Implementation**: HMAC-SHA256 signing and validation

### Authentication Flow
1. Client provides API key or JWT token in request metadata
2. AuthManager validates credentials and generates AuthContext
3. Tool handlers check AuthContext permissions before execution
4. Rate limiting is applied per API key/user

## Best Practices

### For Development
1. Use separate JWT secrets for dev/staging/production
2. Test with different user permission levels
3. Verify rate limiting behavior
4. Test token expiration handling

### For Production
1. Use cryptographically secure JWT secrets (256+ bits)
2. Implement proper key rotation
3. Monitor authentication failures and rate limit violations
4. Use HTTPS for any network transport
5. Implement audit logging for security events

## MCP Specification

This server follows the Model Context Protocol specification with authentication extensions:
https://modelcontextprotocol.io/specification