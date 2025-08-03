import Foundation

public struct ParameterMetadata: Codable, Equatable, Sendable {
    public let name: String
    public let type: String
    public let description: String
    public let required: Bool

    public init(name: String, type: String, description: String, required: Bool = true) {
        self.name = name
        self.type = type
        self.description = description
        self.required = required
    }
}

public struct KernelFunctionMetadata: Codable, Equatable, Sendable {
    public let description: String
    public let parameters: [ParameterMetadata]
    public let returnType: String?

    public init(description: String, parameters: [ParameterMetadata], returnType: String? = nil) {
        self.description = description
        self.parameters = parameters
        self.returnType = returnType
    }
}

extension ParameterMetadata {
    public var jsonType: String {
        let lower = type.lowercased()
        if ["int", "integer"].contains(lower) { return "integer" }
        if ["double", "float", "number", "decimal"].contains(lower) { return "number" }
        if ["bool", "boolean"].contains(lower) { return "boolean" }
        return "string"
    }
}
