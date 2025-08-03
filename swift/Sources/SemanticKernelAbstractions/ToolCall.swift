import Foundation

public struct ToolCall: Codable, Equatable, Sendable {
    public let id: String?
    public let name: String
    public let arguments: String

    public init(id: String? = nil, name: String, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}
