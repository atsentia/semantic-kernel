import Foundation

public struct PluginDescriptor: Sendable {
    public let name: String
    public let description: String
    public let parameters: [ParameterMetadata]
    public let returnType: String?
    public let handler: @Sendable (KernelArguments) async throws -> KernelResult

    public init(name: String, description: String, parameters: [ParameterMetadata] = [], returnType: String? = nil, handler: @escaping @Sendable (KernelArguments) async throws -> KernelResult) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.returnType = returnType
        self.handler = handler
    }
}

public protocol KernelPlugin: Sendable {
    var descriptors: [PluginDescriptor] { get }
    init()
}
