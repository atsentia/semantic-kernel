# Filesystem MCP Server with OAuth 2.1 + PKCE

A production-ready Model Context Protocol (MCP) server implementing full OAuth 2.1 + PKCE authorization following the 2025 MCP specification with comprehensive security features.

## Overview

This server provides enterprise-grade OAuth 2.1 authentication with complete RFC compliance:

- **OAuth 2.1 + PKCE** (RFC 7636) authorization flows
- **Authorization Server Metadata Discovery** (RFC 8414)
- **Token Introspection** (RFC 7662) for validation
- **Resource Indicators** (RFC 8707) for audience validation
- **Protected Resource Metadata** (RFC 9728) discovery
- **Secure token storage** in system Keychain
- **Full MCP 2025 specification compliance**

## OAuth 2.1 Features

### Supported Grant Types
1. **Authorization Code + PKCE** - For interactive client applications
2. **Client Credentials** - For server-to-server authentication  
3. **Refresh Token** - For token renewal without re-authentication

### Security Enhancements
- **PKCE (Proof Key for Code Exchange)** mandatory for all flows
- **State parameter** validation for CSRF protection
- **S256 code challenge method** (SHA256-based)
- **Secure random generation** for all cryptographic values
- **Token introspection** for real-time validation

## Configuration

### Environment Variables

#### Required
- `OAUTH_AUTH_SERVER`: Authorization server URL (e.g., `https://auth.example.com`)
- `OAUTH_RESOURCE_SERVER`: Resource server URL (e.g., `https://api.example.com`)
- `OAUTH_CLIENT_ID`: OAuth 2.1 client identifier

#### Optional
- `OAUTH_CLIENT_SECRET`: Client secret (confidential clients only)
- `OAUTH_REDIRECT_URI`: OAuth redirect URI (default: `http://localhost:8080/callback`)
- `OAUTH_INTROSPECTION_ENDPOINT`: Token introspection endpoint
- `OAUTH_METADATA_ENDPOINT`: Resource metadata endpoint

### Default Scopes
- `filesystem:read` - Read access to allowed directories
- `filesystem:write` - Write access to allowed directories  
- `filesystem:admin` - Administrative filesystem operations

## Authentication Flows

### 1. Authorization Code Flow (Interactive)

**Step 1: Start Authorization**
```swift
let authRequest = try await oauthManager.startAuthorizationFlow()
// User visits authRequest.authorizationURL in browser
```

**Step 2: Handle Callback**
```swift
let tokens = try await oauthManager.exchangeCodeForTokens(
    code: receivedCode,
    state: receivedState, 
    authRequest: authRequest
)
```

### 2. Client Credentials Flow (Server-to-Server)

```swift
let tokens = try await oauthManager.authenticateWithClientCredentials()
```

### 3. Token Usage

```swift
let accessToken = try await oauthManager.getValidAccessToken()
// Use token in Authorization: Bearer <token> header
```

## Server Metadata Discovery

The server automatically discovers OAuth endpoints using RFC 8414:

1. **Protected Resource Metadata** (RFC 9728) - Preferred method
2. **Authorization Server Metadata** (RFC 8414) - Fallback method
3. **Well-known endpoints** - Standard OAuth discovery

**Example Discovery:**
```swift
let metadata = try await oauthManager.discoverServerMetadata()
// Returns: authorization_endpoint, token_endpoint, etc.
```

## Available Tools

All filesystem operations require proper OAuth scopes:

### read_file
- **Required Scope:** `filesystem:read`
- **Token Validation:** Introspection + scope verification
- **Authorization:** Path validation + audience check

### write_file  
- **Required Scope:** `filesystem:write`
- **Token Validation:** Active token with write permissions
- **Authorization:** Content size + path restrictions

### list_directory
- **Required Scope:** `filesystem:read`  
- **Authorization:** Directory access validation

### create_directory
- **Required Scope:** `filesystem:write`
- **Authorization:** Path creation permissions

### get_file_info
- **Required Scope:** `filesystem:read`
- **Authorization:** File metadata access

### search_files
- **Required Scope:** `filesystem:read`
- **Authorization:** Directory search permissions

## Usage

### Building
```bash
swift build --product filesystem-mcp-server-oauth
```

### Running
```bash
# Configure OAuth endpoints
export OAUTH_AUTH_SERVER="https://your-auth-server.com"
export OAUTH_RESOURCE_SERVER="https://your-api-server.com" 
export OAUTH_CLIENT_ID="your-client-id"
export OAUTH_CLIENT_SECRET="your-client-secret" # if confidential client

swift run filesystem-mcp-server-oauth
```

### Authorization Flow Example

1. **Start OAuth flow** (typically done by MCP client):
```bash
# Client initiates OAuth flow and gets authorization URL
# User completes authentication in browser
# Client receives authorization code via redirect
```

2. **Make authenticated requests**:
```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call", 
  "params": {
    "name": "read_file",
    "arguments": {"path": "./data.txt"}
  }
}
```

Note: Access token should be provided in HTTP `Authorization: Bearer <token>` header (in real HTTP transport) or embedded in MCP request metadata.

## Token Management

### Automatic Token Refresh
```swift
// Automatically refreshes expired tokens
let validToken = try await oauthManager.getValidAccessToken()
```

### Token Introspection
```swift  
let introspection = try await oauthManager.introspectToken(accessToken)
// Returns: userId, scopes, clientId, audience, etc.
```

### Secure Storage
- Tokens stored in **system Keychain** with restricted access
- **Automatic encryption** at rest
- **Device-local only** (not synced across devices)

## Error Handling

### OAuth-Specific Errors
- **Invalid configuration** - Missing required OAuth settings
- **State mismatch** - CSRF protection triggered  
- **Token exchange failed** - Authorization code exchange error
- **Token expired** - Access token needs refresh
- **Insufficient scopes** - Required permissions missing
- **Wrong audience** - Resource indicator mismatch

### JSON-RPC Error Codes
- **-32001**: Unauthorized (invalid/expired tokens)
- **-32002**: Forbidden (insufficient scopes/permissions)
- **-32003**: Authentication Error (OAuth flow failures)
- **-32004**: Server Error (network/config issues)

## Production Deployment

### Security Checklist
- [ ] Use HTTPS for all OAuth endpoints
- [ ] Configure proper redirect URIs
- [ ] Implement PKCE for all authorization flows
- [ ] Validate audience claims in tokens
- [ ] Use secure client credentials storage
- [ ] Enable comprehensive audit logging
- [ ] Monitor token introspection failures

### High Availability Setup
```swift
let productionConfig = OAuthConfig(
    authorizationServer: URL(string: "https://auth.production.com")!,
    resourceServer: URL(string: "https://api.production.com")!,
    clientId: "prod-filesystem-mcp",
    clientSecret: "secure-client-secret",
    redirectURI: "https://your-app.com/oauth/callback",
    scopes: ["filesystem:read", "filesystem:write"],
    supportedGrantTypes: [.authorizationCode, .clientCredentials, .refreshToken],
    pkceRequired: true,
    tokenIntrospectionEndpoint: URL(string: "https://auth.production.com/introspect")!
)
```

## Status

✅ **Working** - All compilation errors have been fixed:
- ~~`OAuthConfig.default` visibility issues~~ - Fixed with public access modifier
- ~~`@main` attribute conflicts~~ - Fixed using Task-based execution
- ~~Sendable compliance for concurrent access~~ - Fixed by adding Sendable conformance
- ~~Module structure refactoring needed~~ - Fixed with proper async execution pattern

## RFC Compliance

This server implements the following specifications:

- **RFC 6749**: OAuth 2.0 Authorization Framework
- **RFC 7636**: PKCE (Proof Key for Code Exchange)  
- **RFC 7662**: OAuth 2.0 Token Introspection
- **RFC 8414**: OAuth 2.0 Authorization Server Metadata
- **RFC 8707**: Resource Indicators for OAuth 2.0
- **RFC 9728**: OAuth 2.0 Protected Resource Metadata

## Architecture

### Core Components
- **OAuthManager**: Complete OAuth 2.1 + PKCE implementation
- **PKCEChallenge**: S256 code challenge generation
- **SecureTokenStorage**: Keychain-based token storage
- **HTTPClient**: OAuth endpoint communication
- **ServerMetadata**: Discovery and configuration management

### Security Architecture
1. **Discovery Phase**: Automatic endpoint discovery
2. **Authorization Phase**: PKCE-protected code exchange
3. **Token Phase**: Secure token storage and refresh
4. **Validation Phase**: Real-time token introspection
5. **Authorization Phase**: Scope and audience validation

## Best Practices

### Development
1. Use separate OAuth clients for dev/staging/production
2. Test with different scope combinations
3. Verify PKCE challenge generation
4. Test token refresh scenarios
5. Validate metadata discovery

### Production
1. Use TLS 1.3 for all OAuth communications
2. Implement proper key rotation
3. Monitor OAuth error rates and patterns
4. Use dedicated OAuth infrastructure
5. Implement comprehensive audit trails
6. Regular security assessments

## Integration Examples

### MCP Client Integration
```typescript
// Example MCP client usage (conceptual)
const mcpClient = new MCPClient({
  transport: 'stdio',
  command: 'swift',
  args: ['run', 'filesystem-mcp-server-oauth'],
  oauth: {
    authServer: 'https://auth.example.com',
    clientId: 'mcp-client-id',
    scopes: ['filesystem:read', 'filesystem:write']
  }
});
```

## MCP Specification

This server follows the Model Context Protocol 2025 specification with full OAuth 2.1 compliance:
https://modelcontextprotocol.io/specification