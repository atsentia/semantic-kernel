import Foundation
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import Logging

struct OpenAIClient: Sendable {
    let apiKey: String
    let baseURL: URL
    let apiVersion: String?
    let retry: RetryUtility
    let logger: Logger?
    let useBearer: Bool

    init(apiKey: String? = nil, baseURL: URL? = nil, apiVersion: String? = nil, httpClient: HTTPClientSending = HTTPClient(eventLoopGroupProvider: .singleton), retryConfig: RetryConfig = RetryConfig(), logger: Logger? = nil) {
        self.apiKey = apiKey ?? Environment.apiKey ?? ""
        self.baseURL = baseURL ?? Environment.baseURL ?? URL(string: "https://api.openai.com")!
        self.apiVersion = apiVersion ?? Environment.apiVersion
        self.retry = RetryUtility(client: httpClient, config: retryConfig, logger: logger)
        self.logger = logger
        self.useBearer = self.apiVersion == nil
    }

    func sendJSON<T: Encodable>(_ body: T, path: String, query: [URLQueryItem] = []) async throws -> (HTTPResponseStatus, ByteBuffer) {
        try Task.checkCancellation()
        var url = baseURL.appendingPathComponent(path)
        if !query.isEmpty {
            var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            comps.queryItems = query
            url = comps.url!
        }
        var req = HTTPClientRequest(url: url.absoluteString)
        req.method = .POST
        if useBearer {
            req.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
        } else {
            req.headers.add(name: "api-key", value: apiKey)
        }
        req.headers.add(name: "Content-Type", value: "application/json")
        let data = try JSONEncoder().encode(body)
        req.body = .bytes(data)
        logger?.debug("sending request to \(url)")
        return try await retry.send(req)
    }
}
