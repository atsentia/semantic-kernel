import Foundation

public struct FunctionDefinition: Codable, Equatable, Sendable {
    public struct JSONSchema: Codable, Equatable, Sendable {
        public struct Property: Codable, Equatable, Sendable {
            public let type: String
            public let description: String
            public init(type: String, description: String) {
                self.type = type
                self.description = description
            }
        }
        public let type: String
        public var properties: [String: Property]
        public var required: [String]?
        public init(properties: [String: Property], required: [String]?) {
            self.type = "object"
            self.properties = properties
            self.required = required
        }
    }

    public let name: String
    public let description: String
    public let parameters: JSONSchema
    public let returns: String?

    public init(name: String, description: String, parameters: JSONSchema, returns: String?) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.returns = returns
    }
}
