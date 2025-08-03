import Foundation

public struct KernelResult: Sendable {
    public var output: String

    public init(_ output: String) {
        self.output = output
    }
}
