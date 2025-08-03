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
