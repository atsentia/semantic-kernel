import Foundation

public struct KernelArguments: Sendable {
    public private(set) var entries: [String: String]

    public init(_ entries: [String: String] = [:]) {
        self.entries = entries
    }

    public subscript(key: String) -> String? {
        get { entries[key] }
        set { entries[key] = newValue }
    }
}
