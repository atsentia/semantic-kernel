import Foundation
import AsyncHTTPClient
import NIOCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI

public final class HttpPlugin: KernelPlugin {
    let client: HTTPClientSending

    public convenience init() {
        self.init(client: HTTPClient(eventLoopGroupProvider: .singleton))
    }

    public init(client: HTTPClientSending) {
        self.client = client
    }

    public var descriptors: [PluginDescriptor] {
        [
            PluginDescriptor(
                name: "get",
                description: "Send an HTTP GET request and return the response body as text",
                parameters: [ParameterMetadata(name: "url", type: "String", description: "URL to fetch")],
                returnType: "String"
            ) { [self] args in
                guard let url = args["url"] else { throw KernelError.invalidState("missing url") }
                var req = HTTPClientRequest(url: url)
                req.method = .GET
                let (status, buffer) = try await self.client.send(request: req, timeout: .seconds(30))
                guard status == .ok else { throw AIServiceError.badResponse(status: Int(status.code)) }
                let bytes = buffer.getBytes(at: 0, length: buffer.readableBytes) ?? []
                let body = String(decoding: bytes, as: UTF8.self)
                return KernelResult(body)
            }
        ]
    }
}

