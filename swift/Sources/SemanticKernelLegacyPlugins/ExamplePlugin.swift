import SemanticKernelCore

/// Example plugin with a single function.
public struct ExamplePlugin {
    public init() {}

    public func greet(name: String) async throws -> String {
        // TODO: implement plugin logic
        return "Hello, \(name)!"
    }
}
