import Foundation
import Crypto

// MARK: - OAuth 2.1 Configuration

public struct OAuthConfig: Sendable {
    let authorizationServer: URL
    let resourceServer: URL
    let clientId: String
    let clientSecret: String? // Optional for public clients
    let redirectURI: String
    let scopes: [String]
    let supportedGrantTypes: [GrantType]
    let pkceRequired: Bool
    let tokenIntrospectionEndpoint: URL
    let resourceMetadataEndpoint: URL?
    
    enum GrantType: String, CaseIterable {
        case authorizationCode = "authorization_code"
        case clientCredentials = "client_credentials"
        case refreshToken = "refresh_token"
        case deviceCode = "urn:ietf:params:oauth:grant-type:device_code"
    }
    
    public static let `default` = OAuthConfig(
        authorizationServer: URL(string: ProcessInfo.processInfo.environment["OAUTH_AUTH_SERVER"] ?? "https://auth.example.com")!,
        resourceServer: URL(string: ProcessInfo.processInfo.environment["OAUTH_RESOURCE_SERVER"] ?? "https://api.example.com")!,
        clientId: ProcessInfo.processInfo.environment["OAUTH_CLIENT_ID"] ?? "mcp-filesystem-client",
        clientSecret: ProcessInfo.processInfo.environment["OAUTH_CLIENT_SECRET"],
        redirectURI: ProcessInfo.processInfo.environment["OAUTH_REDIRECT_URI"] ?? "http://localhost:8080/callback",
        scopes: ["filesystem:read", "filesystem:write", "filesystem:admin"],
        supportedGrantTypes: [.authorizationCode, .clientCredentials, .refreshToken],
        pkceRequired: true,
        tokenIntrospectionEndpoint: URL(string: ProcessInfo.processInfo.environment["OAUTH_INTROSPECTION_ENDPOINT"] ?? "https://auth.example.com/oauth/introspect")!,
        resourceMetadataEndpoint: URL(string: ProcessInfo.processInfo.environment["OAUTH_METADATA_ENDPOINT"] ?? "https://api.example.com/.well-known/oauth-resource-metadata")
    )
}

// MARK: - OAuth 2.1 Manager

public class OAuthManager {
    private let config: OAuthConfig
    private let keychain: SecureTokenStorage
    private let httpClient: HTTPClient
    
    public init(config: OAuthConfig = .default) {
        self.config = config
        self.keychain = SecureTokenStorage()
        self.httpClient = HTTPClient()
    }
    
    // MARK: - Server Metadata Discovery (RFC 8414 + RFC 9728)
    
    public func discoverServerMetadata() async throws -> ServerMetadata {
        // Try RFC 9728 Protected Resource Metadata first
        if let metadataEndpoint = config.resourceMetadataEndpoint {
            do {
                let metadata = try await httpClient.fetchMetadata(from: metadataEndpoint)
                return metadata
            } catch {
                // Fall back to well-known endpoints
            }
        }
        
        // RFC 8414 Authorization Server Metadata
        let wellKnownURL = config.authorizationServer.appendingPathComponent("/.well-known/oauth-authorization-server")
        let authMetadata = try await httpClient.fetchAuthorizationServerMetadata(from: wellKnownURL)
        
        return ServerMetadata(
            authorizationEndpoint: authMetadata.authorization_endpoint,
            tokenEndpoint: authMetadata.token_endpoint,
            introspectionEndpoint: authMetadata.introspection_endpoint,
            supportedGrantTypes: authMetadata.grant_types_supported,
            supportedScopes: authMetadata.scopes_supported,
            pkceRequired: authMetadata.code_challenge_methods_supported?.contains("S256") ?? false
        )
    }
    
    // MARK: - Authorization Code Flow with PKCE (RFC 7636)
    
    public func startAuthorizationFlow() async throws -> AuthorizationRequest {
        let metadata = try await discoverServerMetadata()
        let pkce = PKCEChallenge()
        let state = SecureRandomGenerator.generateState()
        
        // RFC 8707 Resource Indicators
        let resourceIndicator = config.resourceServer.absoluteString
        
        var components = URLComponents(url: metadata.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "scope", value: config.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: pkce.codeChallengeMethod),
            URLQueryItem(name: "resource", value: resourceIndicator) // RFC 8707
        ]
        
        guard let authURL = components.url else {
            throw OAuthError.invalidConfiguration
        }
        
        return AuthorizationRequest(
            authorizationURL: authURL,
            state: state,
            pkce: pkce,
            metadata: metadata
        )
    }
    
    public func exchangeCodeForTokens(
        code: String,
        state: String,
        authRequest: AuthorizationRequest
    ) async throws -> TokenSet {
        guard state == authRequest.state else {
            throw OAuthError.stateMismatch
        }
        
        let metadata = authRequest.metadata
        
        var request = URLRequest(url: metadata.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Client authentication (RFC 6749 Section 2.3)
        if let clientSecret = config.clientSecret {
            // Confidential client - use client secret
            let credentials = "\(config.clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        
        var bodyParams = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": config.redirectURI,
            "code_verifier": authRequest.pkce.codeVerifier,
            "resource": config.resourceServer.absoluteString // RFC 8707
        ]
        
        // Public client authentication
        if config.clientSecret == nil {
            bodyParams["client_id"] = config.clientId
        }
        
        let body = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data)
            throw OAuthError.tokenExchangeFailed(errorResponse?.error ?? "unknown_error")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let tokens = TokenSet(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            tokenType: tokenResponse.token_type,
            expiresIn: tokenResponse.expires_in,
            scope: tokenResponse.scope?.components(separatedBy: " ") ?? config.scopes
        )
        
        try await keychain.store(tokens: tokens)
        return tokens
    }
    
    // MARK: - Client Credentials Flow (RFC 6749 Section 4.4)
    
    public func authenticateWithClientCredentials() async throws -> TokenSet {
        let metadata = try await discoverServerMetadata()
        
        var request = URLRequest(url: metadata.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Client authentication
        if let clientSecret = config.clientSecret {
            let credentials = "\(config.clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        
        var bodyParams = [
            "grant_type": "client_credentials",
            "scope": config.scopes.joined(separator: " "),
            "resource": config.resourceServer.absoluteString
        ]
        
        if config.clientSecret == nil {
            bodyParams["client_id"] = config.clientId
        }
        
        let body = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data)
            throw OAuthError.authenticationFailed(errorResponse?.error ?? "unknown_error")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let tokens = TokenSet(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token,
            tokenType: tokenResponse.token_type,
            expiresIn: tokenResponse.expires_in,
            scope: tokenResponse.scope?.components(separatedBy: " ") ?? config.scopes
        )
        
        try await keychain.store(tokens: tokens)
        return tokens
    }
    
    // MARK: - Token Management
    
    public func getValidAccessToken() async throws -> String {
        guard let tokens = try await keychain.retrieveTokens() else {
            throw OAuthError.noValidTokens
        }
        
        if tokens.isExpired {
            if let refreshToken = tokens.refreshToken {
                let newTokens = try await refreshTokens(refreshToken: refreshToken)
                return newTokens.accessToken
            } else {
                throw OAuthError.tokenExpired
            }
        }
        
        return tokens.accessToken
    }
    
    private func refreshTokens(refreshToken: String) async throws -> TokenSet {
        let metadata = try await discoverServerMetadata()
        
        var request = URLRequest(url: metadata.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        if let clientSecret = config.clientSecret {
            let credentials = "\(config.clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        
        var bodyParams = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken
        ]
        
        if config.clientSecret == nil {
            bodyParams["client_id"] = config.clientId
        }
        
        let body = bodyParams.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                            .joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data)
            throw OAuthError.tokenRefreshFailed(errorResponse?.error ?? "unknown_error")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        let newTokens = TokenSet(
            accessToken: tokenResponse.access_token,
            refreshToken: tokenResponse.refresh_token ?? refreshToken, // Keep old refresh token if not provided
            tokenType: tokenResponse.token_type,
            expiresIn: tokenResponse.expires_in,
            scope: tokenResponse.scope?.components(separatedBy: " ") ?? config.scopes
        )
        
        try await keychain.store(tokens: newTokens)
        return newTokens
    }
    
    // MARK: - Token Introspection (RFC 7662)
    
    public func introspectToken(_ token: String) async throws -> TokenIntrospectionResult {
        var request = URLRequest(url: config.tokenIntrospectionEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Authenticate with resource server credentials
        if let clientSecret = config.clientSecret {
            let credentials = "\(config.clientId):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        }
        
        let body = "token=\(token)&token_type_hint=access_token"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            throw OAuthError.introspectionFailed
        }
        
        let introspectionResponse = try JSONDecoder().decode(IntrospectionResponse.self, from: data)
        
        if !introspectionResponse.active {
            throw OAuthError.tokenInvalid
        }
        
        return TokenIntrospectionResult(
            userId: introspectionResponse.sub ?? "unknown",
            scopes: introspectionResponse.scope?.components(separatedBy: " ") ?? [],
            clientId: introspectionResponse.client_id ?? config.clientId,
            expiresAt: introspectionResponse.exp.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            audience: introspectionResponse.aud
        )
    }
    
    // MARK: - Authorization Validation
    
    public func validateAndAuthorize(token: String, requiredScopes: [String], resource: String? = nil) async throws -> UserContext {
        let introspection = try await introspectToken(token)
        
        // Check required scopes
        for requiredScope in requiredScopes {
            guard introspection.scopes.contains(requiredScope) else {
                throw OAuthError.insufficientScopes(required: requiredScopes, available: introspection.scopes)
            }
        }
        
        // Check resource indicator if provided
        if let resource = resource, let audience = introspection.audience {
            guard audience.contains(resource) else {
                throw OAuthError.wrongAudience
            }
        }
        
        return UserContext(
            userId: introspection.userId,
            scopes: introspection.scopes,
            clientId: introspection.clientId,
            expiresAt: introspection.expiresAt
        )
    }
}

// MARK: - PKCE Implementation

public struct PKCEChallenge {
    let codeVerifier: String
    let codeChallenge: String
    let codeChallengeMethod: String = "S256"
    
    init() {
        self.codeVerifier = Self.generateCodeVerifier()
        self.codeChallenge = Self.generateCodeChallenge(from: codeVerifier)
    }
    
    private static func generateCodeVerifier() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64URLEncodedString()
    }
    
    private static func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }
}

// MARK: - Data Models

public struct AuthorizationRequest {
    let authorizationURL: URL
    let state: String
    let pkce: PKCEChallenge
    let metadata: ServerMetadata
}

public struct TokenSet: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: Int
    let scope: [String]
    private let issuedAt: Date
    
    init(accessToken: String, refreshToken: String?, tokenType: String, expiresIn: Int, scope: [String]) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenType = tokenType
        self.expiresIn = expiresIn
        self.scope = scope
        self.issuedAt = Date()
    }
    
    var isExpired: Bool {
        let expirationDate = issuedAt.addingTimeInterval(TimeInterval(expiresIn - 60)) // 60s buffer
        return Date() >= expirationDate
    }
}

public struct UserContext {
    let userId: String
    let scopes: [String]
    let clientId: String
    let expiresAt: Date?
}

public struct TokenIntrospectionResult {
    let userId: String
    let scopes: [String]
    let clientId: String
    let expiresAt: Date?
    let audience: [String]?
}

public struct ServerMetadata {
    let authorizationEndpoint: URL
    let tokenEndpoint: URL
    let introspectionEndpoint: URL?
    let supportedGrantTypes: [String]
    let supportedScopes: [String]?
    let pkceRequired: Bool
}

// MARK: - Network Types

private struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String?
    let token_type: String
    let expires_in: Int
    let scope: String?
}

private struct IntrospectionResponse: Codable {
    let active: Bool
    let scope: String?
    let client_id: String?
    let sub: String?
    let exp: Int?
    let aud: [String]?
}

private struct AuthorizationServerMetadata: Codable {
    let authorization_endpoint: URL
    let token_endpoint: URL
    let introspection_endpoint: URL?
    let grant_types_supported: [String]
    let scopes_supported: [String]?
    let code_challenge_methods_supported: [String]?
}

private struct OAuthErrorResponse: Codable {
    let error: String
    let error_description: String?
}

// MARK: - Errors

public enum OAuthError: Error, LocalizedError {
    case invalidConfiguration
    case stateMismatch
    case tokenExchangeFailed(String)
    case authenticationFailed(String)
    case tokenRefreshFailed(String)
    case introspectionFailed
    case tokenInvalid
    case tokenExpired
    case noValidTokens
    case insufficientScopes(required: [String], available: [String])
    case wrongAudience
    case invalidResponse
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration: return "Invalid OAuth configuration"
        case .stateMismatch: return "OAuth state parameter mismatch"
        case .tokenExchangeFailed(let error): return "Token exchange failed: \(error)"
        case .authenticationFailed(let error): return "Authentication failed: \(error)"
        case .tokenRefreshFailed(let error): return "Token refresh failed: \(error)"
        case .introspectionFailed: return "Token introspection failed"
        case .tokenInvalid: return "Access token is invalid"
        case .tokenExpired: return "Access token has expired"
        case .noValidTokens: return "No valid tokens available"
        case .insufficientScopes(let required, let available):
            return "Insufficient scopes. Required: \(required), Available: \(available)"
        case .wrongAudience: return "Token audience mismatch"
        case .invalidResponse: return "Invalid server response"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        }
    }
    
    var jsonrpcCode: Int {
        switch self {
        case .invalidConfiguration, .stateMismatch, .tokenInvalid, .tokenExpired, .noValidTokens:
            return -32001 // Unauthorized
        case .insufficientScopes, .wrongAudience:
            return -32002 // Forbidden
        case .tokenExchangeFailed, .authenticationFailed, .tokenRefreshFailed, .introspectionFailed:
            return -32003 // Authentication Error
        case .invalidResponse, .networkError:
            return -32004 // Server Error
        }
    }
}

// MARK: - Utility Classes

private class HTTPClient {
    func fetchMetadata(from url: URL) async throws -> ServerMetadata {
        let (data, _) = try await URLSession.shared.data(from: url)
        let metadata = try JSONDecoder().decode(AuthorizationServerMetadata.self, from: data)
        return ServerMetadata(
            authorizationEndpoint: metadata.authorization_endpoint,
            tokenEndpoint: metadata.token_endpoint,
            introspectionEndpoint: metadata.introspection_endpoint,
            supportedGrantTypes: metadata.grant_types_supported,
            supportedScopes: metadata.scopes_supported,
            pkceRequired: metadata.code_challenge_methods_supported?.contains("S256") ?? false
        )
    }
    
    func fetchAuthorizationServerMetadata(from url: URL) async throws -> AuthorizationServerMetadata {
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(AuthorizationServerMetadata.self, from: data)
    }
}

private class SecureTokenStorage {
    private let service = "com.swiftsemantickernel.mcp.oauth"
    private let account = "oauth_tokens"
    
    func store(tokens: TokenSet) async throws {
        let data = try JSONEncoder().encode(tokens)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw OAuthError.invalidConfiguration
        }
    }
    
    func retrieveTokens() async throws -> TokenSet? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }
        
        return try JSONDecoder().decode(TokenSet.self, from: data)
    }
}

private enum SecureRandomGenerator {
    static func generateState() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64URLEncodedString()
    }
}

// MARK: - Extensions

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}