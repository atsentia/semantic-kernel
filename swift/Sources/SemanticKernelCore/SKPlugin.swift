import Foundation
import SemanticKernelAbstractions

public protocol SKPlugin: Sendable {
    static var pluginName: String { get }
    func register(with kernel: Kernel) async
}
