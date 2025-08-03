import Foundation
import AsyncHTTPClient
import NIOCore
import NIOHTTP1

public protocol HTTPClientSending: Sendable {
    func send(request: HTTPClientRequest, timeout: TimeAmount) async throws -> (HTTPResponseStatus, ByteBuffer)
}

extension HTTPClient: HTTPClientSending {
    public func send(request: HTTPClientRequest, timeout: TimeAmount) async throws -> (HTTPResponseStatus, ByteBuffer) {
        let response = try await execute(request, timeout: timeout)
        let body = try await response.body.collect(upTo: 1 << 20)
        return (response.status, body)
    }
}

public struct MockHTTPClient: HTTPClientSending {
    let status: HTTPResponseStatus
    let body: ByteBuffer
    public func send(request: HTTPClientRequest, timeout: TimeAmount) async throws -> (HTTPResponseStatus, ByteBuffer) {
        return (status, body)
    }
}

public final class SequenceMockHTTPClient: HTTPClientSending, @unchecked Sendable {
    public private(set) var requests: [HTTPClientRequest] = []
    private var responses: [(HTTPResponseStatus, ByteBuffer)]

    public init(responses: [(HTTPResponseStatus, ByteBuffer)]) {
        self.responses = responses
    }

    public func send(request: HTTPClientRequest, timeout: TimeAmount) async throws -> (HTTPResponseStatus, ByteBuffer) {
        requests.append(request)
        if !responses.isEmpty {
            return responses.removeFirst()
        }
        return (.ok, ByteBuffer())
    }
}
