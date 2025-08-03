import Foundation
import AsyncHTTPClient
import NIOCore
import NIOHTTP1
import Logging

public struct RetryConfig: Sendable {
    let maxRetries: Int
    let baseDelay: Double
    let timeoutSeconds: Double

    public init(maxRetries: Int = 2, baseDelay: Double = 0.5, timeoutSeconds: Double = 30) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.timeoutSeconds = timeoutSeconds
    }
}

struct RetryUtility: Sendable {
    let client: HTTPClientSending
    let config: RetryConfig
    let logger: Logger?

    func send(_ request: HTTPClientRequest) async throws -> (HTTPResponseStatus, ByteBuffer) {
        var attempt = 0
        var backoff = config.baseDelay
        while true {
            try Task.checkCancellation()
            let timeout = TimeAmount.milliseconds(Int64(config.timeoutSeconds * 1000))
            let (status, buffer) = try await client.send(request: request, timeout: timeout)
            if (status == .tooManyRequests || status.code >= 500) && attempt < config.maxRetries {
                attempt += 1
                logger?.warning("retry \(attempt) due to status \(status.code)")
                try await Task.sleep(nanoseconds: UInt64(backoff * 1_000_000_000))
                backoff *= 2
                continue
            }
            return (status, buffer)
        }
    }
}
