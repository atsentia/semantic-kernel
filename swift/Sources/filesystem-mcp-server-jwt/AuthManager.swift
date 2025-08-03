import Foundation
import Crypto

public struct AuthConfig: Sendable {
    let jwtSecret: String
    let tokenExpiration: TimeInterval // seconds
    let allowedAPIKeys: [String: UserPermissions]
    let rateLimiting: RateLimitConfig?
    
    public static let `default` = AuthConfig(
        jwtSecret: ProcessInfo.processInfo.environment["MCP_JWT_SECRET"] ?? "your-secret-key-change-this",
        tokenExpiration: 3600, // 1 hour
        allowedAPIKeys: [
            "demo-api-key": UserPermissions(
                userId: "demo-user",
                scopes: ["filesystem:read", "filesystem:write"],
                allowedPaths: nil, // nil = use default security manager paths
                maxFileSize: nil,  // nil = use default limits
                canWrite: true,
                canDelete: false
            )
        ],
        rateLimiting: RateLimitConfig(
            requestsPerMinute: 60,
            requestsPerHour: 1000
        )
    )
}

public struct UserPermissions: Sendable {
    let userId: String
    let scopes: Set<String>
    let allowedPaths: Set<String>?
    let maxFileSize: Int?
    let canWrite: Bool
    let canDelete: Bool
}

public struct RateLimitConfig: Sendable {
    let requestsPerMinute: Int
    let requestsPerHour: Int
}

public class AuthManager {
    private let config: AuthConfig
    private var rateLimitTracker: [String: RateLimitInfo] = [:]
    
    public init(config: AuthConfig = AuthConfig.default) {
        self.config = config
    }
    
    // MARK: - Authentication
    
    public func authenticate(apiKey: String? = nil, jwt: String? = nil) -> AuthResult {
        if let jwt = jwt {
            return validateJWT(jwt)
        } else if let apiKey = apiKey {
            return authenticateAPIKey(apiKey)
        } else {
            return .failure(.missingCredentials)
        }
    }
    
    private func authenticateAPIKey(_ apiKey: String) -> AuthResult {
        guard let permissions = config.allowedAPIKeys[apiKey] else {
            return .failure(.invalidAPIKey)
        }
        
        // Check rate limiting
        if let rateLimitConfig = config.rateLimiting {
            let now = Date()
            let info = rateLimitTracker[apiKey, default: RateLimitInfo()]
            
            // Clean old entries
            info.requests = info.requests.filter { now.timeIntervalSince($0) < 3600 } // 1 hour
            
            let recentRequests = info.requests.filter { now.timeIntervalSince($0) < 60 } // 1 minute
            
            if recentRequests.count >= rateLimitConfig.requestsPerMinute ||
               info.requests.count >= rateLimitConfig.requestsPerHour {
                return .failure(.rateLimited)
            }
            
            info.requests.append(now)
            rateLimitTracker[apiKey] = info
        }
        
        // Generate JWT token for this session
        do {
            let jwt = try generateJWT(for: permissions)
            return .success(AuthContext(
                userId: permissions.userId,
                permissions: permissions,
                token: jwt,
                expiresAt: Date().addingTimeInterval(config.tokenExpiration)
            ))
        } catch {
            return .failure(.tokenGenerationFailed)
        }
    }
    
    private func validateJWT(_ token: String) -> AuthResult {
        do {
            let jwt = try JWT.decode(token, secret: config.jwtSecret)
            
            guard jwt.expiresAt > Date() else {
                return .failure(.tokenExpired)
            }
            
            guard let userId = jwt.payload["userId"] as? String,
                  let scopesArray = jwt.payload["scopes"] as? [String] else {
                return .failure(.invalidToken)
            }
            
            let permissions = UserPermissions(
                userId: userId,
                scopes: Set(scopesArray),
                allowedPaths: (jwt.payload["allowedPaths"] as? [String]).map(Set.init),
                maxFileSize: jwt.payload["maxFileSize"] as? Int,
                canWrite: jwt.payload["canWrite"] as? Bool ?? false,
                canDelete: jwt.payload["canDelete"] as? Bool ?? false
            )
            
            return .success(AuthContext(
                userId: userId,
                permissions: permissions,
                token: token,
                expiresAt: jwt.expiresAt
            ))
        } catch {
            return .failure(.invalidToken)
        }
    }
    
    // MARK: - Authorization
    
    public func authorizeFileAccess(context: AuthContext, path: String, operation: FileOperation) -> Bool {
        // Check operation permissions
        switch operation {
        case .read:
            guard context.permissions.scopes.contains("filesystem:read") else { return false }
        case .write:
            guard context.permissions.scopes.contains("filesystem:write") && 
                  context.permissions.canWrite else { return false }
        case .delete:
            guard context.permissions.scopes.contains("filesystem:write") && 
                  context.permissions.canDelete else { return false }
        }
        
        // Check path permissions (if user has specific path restrictions)
        if let allowedPaths = context.permissions.allowedPaths {
            let normalizedPath = URL(fileURLWithPath: path).standardized.path
            let hasAccess = allowedPaths.contains { allowedPath in
                normalizedPath.hasPrefix(URL(fileURLWithPath: allowedPath).standardized.path)
            }
            guard hasAccess else { return false }
        }
        
        // Check file size limits for write operations
        if case .write(let size) = operation,
           let maxSize = context.permissions.maxFileSize,
           size > maxSize {
            return false
        }
        
        return true
    }
    
    public func hasScope(context: AuthContext, requiredScope: String) -> Bool {
        context.permissions.scopes.contains(requiredScope)
    }
    
    // MARK: - JWT Generation
    
    private func generateJWT(for permissions: UserPermissions) throws -> String {
        let payload: [String: Any] = [
            "userId": permissions.userId,
            "scopes": Array(permissions.scopes),
            "allowedPaths": permissions.allowedPaths?.map { $0 } ?? [],
            "maxFileSize": permissions.maxFileSize as Any,
            "canWrite": permissions.canWrite,
            "canDelete": permissions.canDelete,
            "iat": Int(Date().timeIntervalSince1970),
            "exp": Int(Date().addingTimeInterval(config.tokenExpiration).timeIntervalSince1970)
        ]
        
        return try JWT.encode(payload: payload, secret: config.jwtSecret)
    }
}

// MARK: - Data Models

public struct AuthContext {
    let userId: String
    let permissions: UserPermissions
    let token: String
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

public enum FileOperation {
    case read
    case write(size: Int)
    case delete
}

public enum AuthResult {
    case success(AuthContext)
    case failure(AuthError)
}

public enum AuthError: Error, LocalizedError {
    case missingCredentials
    case invalidAPIKey
    case invalidToken
    case tokenExpired
    case tokenGenerationFailed
    case rateLimited
    case insufficientPermissions
    case pathNotAllowed
    
    public var errorDescription: String? {
        switch self {
        case .missingCredentials: return "Missing authentication credentials"
        case .invalidAPIKey: return "Invalid API key provided"
        case .invalidToken: return "Invalid or malformed token"
        case .tokenExpired: return "Authentication token has expired"
        case .tokenGenerationFailed: return "Failed to generate authentication token"
        case .rateLimited: return "Too many requests, rate limit exceeded"
        case .insufficientPermissions: return "Insufficient permissions for this operation"
        case .pathNotAllowed: return "Access to this path is not permitted"
        }
    }
    
    var jsonrpcCode: Int {
        switch self {
        case .missingCredentials, .invalidAPIKey, .invalidToken, .tokenExpired:
            return -32001 // Unauthorized
        case .insufficientPermissions, .pathNotAllowed:
            return -32002 // Forbidden  
        case .rateLimited:
            return -32003 // Rate Limited
        case .tokenGenerationFailed:
            return -32004 // Internal Error
        }
    }
}

private class RateLimitInfo {
    var requests: [Date] = []
}

// MARK: - Simple JWT Implementation

private struct JWT {
    let header: [String: Any]
    let payload: [String: Any]
    let expiresAt: Date
    
    static func encode(payload: [String: Any], secret: String) throws -> String {
        let header = ["alg": "HS256", "typ": "JWT"]
        
        let headerData = try JSONSerialization.data(withJSONObject: header)
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        
        let encodedHeader = headerData.base64URLEncodedString()
        let encodedPayload = payloadData.base64URLEncodedString()
        
        let signingInput = "\(encodedHeader).\(encodedPayload)"
        let signature = try hmacSHA256(data: signingInput.data(using: .utf8)!, secret: secret)
        let encodedSignature = signature.base64URLEncodedString()
        
        return "\(encodedHeader).\(encodedPayload).\(encodedSignature)"
    }
    
    static func decode(_ token: String, secret: String) throws -> JWT {
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else {
            throw AuthError.invalidToken
        }
        
        guard let headerData = Data(base64URLEncoded: parts[0]),
              let payloadData = Data(base64URLEncoded: parts[1]),
              let signatureData = Data(base64URLEncoded: parts[2]) else {
            throw AuthError.invalidToken
        }
        
        // Verify signature
        let signingInput = "\(parts[0]).\(parts[1])"
        let expectedSignature = try hmacSHA256(data: signingInput.data(using: .utf8)!, secret: secret)
        
        guard signatureData == expectedSignature else {
            throw AuthError.invalidToken
        }
        
        let header = try JSONSerialization.jsonObject(with: headerData) as? [String: Any] ?? [:]
        let payload = try JSONSerialization.jsonObject(with: payloadData) as? [String: Any] ?? [:]
        
        let exp = payload["exp"] as? Int ?? 0
        let expiresAt = Date(timeIntervalSince1970: TimeInterval(exp))
        
        return JWT(header: header, payload: payload, expiresAt: expiresAt)
    }
    
    private static func hmacSHA256(data: Data, secret: String) throws -> Data {
        let key = SymmetricKey(data: secret.data(using: .utf8)!)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: key)
        return Data(signature)
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    init?(base64URLEncoded string: String) {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // Add padding if needed
        while base64.count % 4 != 0 {
            base64 += "="
        }
        
        self.init(base64Encoded: base64)
    }
}