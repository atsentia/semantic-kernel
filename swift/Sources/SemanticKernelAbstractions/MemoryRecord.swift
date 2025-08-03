import Foundation

public typealias MemoryRecordID = String

public struct MemoryRecord: Codable, Sendable {
    public let id: MemoryRecordID
    public var text: String?
    public var embedding: [Double]?
    public var metadata: [String: String]?
    public var timestamp: Date?

    public init(id: MemoryRecordID,
                text: String? = nil,
                embedding: [Double]? = nil,
                metadata: [String: String]? = nil,
                timestamp: Date? = nil) {
        self.id = id
        self.text = text
        self.embedding = embedding
        self.metadata = metadata
        self.timestamp = timestamp
    }
}
