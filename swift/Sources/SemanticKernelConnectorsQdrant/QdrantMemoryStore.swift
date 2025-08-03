import Foundation
import AsyncHTTPClient
import NIOCore
import SemanticKernelAbstractions
import SemanticKernelCore

public final class QdrantMemoryStore: MemoryStore, @unchecked Sendable {
    let baseURL: URL
    let collection: String
    let apiKey: String?
    let client: HTTPClientSending

    public init(url: URL, collection: String = "sk", apiKey: String? = nil, client: HTTPClientSending = HTTPClient(eventLoopGroupProvider: .singleton)) {
        self.baseURL = url
        self.collection = collection
        self.apiKey = apiKey
        self.client = client
    }

    public func store(_ record: MemoryRecord, in collection: String) async throws {
        try Task.checkCancellation()
        var point: [String: Any] = ["id": record.id]
        if let embedding = record.embedding { point["vector"] = embedding }
        var payload: [String: Any] = [:]
        if let text = record.text { payload["text"] = text }
        if let meta = record.metadata { payload["metadata"] = meta }
        if !payload.isEmpty { point["payload"] = payload }
        let body: [String: Any] = ["points": [point]]
        let data = try JSONSerialization.data(withJSONObject: body)
        var request = HTTPClientRequest(url: baseURL.appendingPathComponent("/collections/\(self.collection)/points?wait=true").absoluteString)
        request.method = .PUT
        request.headers.add(name: "Content-Type", value: "application/json")
        if let apiKey { request.headers.add(name: "api-key", value: apiKey) }
        request.body = .bytes(data)
        let (status, _) = try await client.send(request: request, timeout: .seconds(30))
        guard (200...299).contains(Int(status.code)) else {
            throw MemoryStoreError.badResponse(status: Int(status.code))
        }
    }

    public func get(id: String, in collection: String) async throws -> MemoryRecord? {
        try Task.checkCancellation()
        var request = HTTPClientRequest(url: baseURL.appendingPathComponent("/collections/\(self.collection)/points/\(id)?with_payload=true&with_vector=true").absoluteString)
        request.method = .GET
        if let apiKey { request.headers.add(name: "api-key", value: apiKey) }
        let (status, buffer) = try await client.send(request: request, timeout: .seconds(30))
        if status == .notFound { return nil }
        guard status == .ok else { throw MemoryStoreError.badResponse(status: Int(status.code)) }
        let bytes = buffer.getBytes(at: 0, length: buffer.readableBytes) ?? []
        var parser = SimpleJSONDecoder(data: Data(bytes))
        let json = try parser.decode()
        guard case let .object(obj) = json,
              case let .object(result) = obj["result"] else {
            throw MemoryStoreError.invalidResponse
        }
        let recordId: String
        if let idVal = result["id"] {
            switch idVal {
            case .string(let s): recordId = s
            case .number(let n): recordId = String(Int(n))
            default: recordId = id
            }
        } else {
            recordId = id
        }
        var text: String? = nil
        var meta: [String: String]? = nil
        if case let .object(payload) = result["payload"] {
            if case let .string(t) = payload["text"] { text = t }
            if case let .object(mo) = payload["metadata"] {
                var mm: [String: String] = [:]
                for (k,v) in mo { if case let .string(s) = v { mm[k] = s } }
                meta = mm
            }
        }
        var vector: [Double]? = nil
        if case let .array(vec) = result["vector"] {
            vector = vec.compactMap { val in if case let .number(d) = val { return d } else { return nil } }
        }
        return MemoryRecord(id: recordId, text: text, embedding: vector, metadata: meta)
    }

    public func search(in collection: String, embedding: [Double], limit: Int) async throws -> [MemoryRecord] {
        try Task.checkCancellation()
        let body: [String: Any] = [
            "vector": embedding,
            "limit": limit,
            "with_payload": true,
            "with_vector": false
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        var request = HTTPClientRequest(url: baseURL.appendingPathComponent("/collections/\(self.collection)/points/search").absoluteString)
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        if let apiKey { request.headers.add(name: "api-key", value: apiKey) }
        request.body = .bytes(data)
        let (status, buffer) = try await client.send(request: request, timeout: .seconds(30))
        guard status == .ok else { throw MemoryStoreError.badResponse(status: Int(status.code)) }
        let bytes = buffer.getBytes(at: 0, length: buffer.readableBytes) ?? []
        var parser = SimpleJSONDecoder(data: Data(bytes))
        let json = try parser.decode()
        guard case let .object(obj) = json,
              case let .array(resArray) = obj["result"] else { throw MemoryStoreError.invalidResponse }
        var records: [MemoryRecord] = []
        records.reserveCapacity(resArray.count)
        for itemVal in resArray {
            guard case let .object(item) = itemVal else { continue }
            var idStr = ""
            if let idVal = item["id"] {
                switch idVal {
                case .string(let s): idStr = s
                case .number(let n): idStr = String(Int(n))
                default: break
                }
            }
            var text: String? = nil
            var meta: [String: String]? = nil
            if case let .object(payload) = item["payload"] {
                if case let .string(t) = payload["text"] { text = t }
                if case let .object(mo) = payload["metadata"] {
                    var mm: [String: String] = [:]
                    for (k,v) in mo { if case let .string(s) = v { mm[k] = s } }
                    meta = mm
                }
            }
            records.append(MemoryRecord(id: idStr, text: text, embedding: nil, metadata: meta))
        }
        return records
    }
}
