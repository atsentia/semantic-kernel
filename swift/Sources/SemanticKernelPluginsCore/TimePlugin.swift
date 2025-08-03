import Foundation
import SemanticKernelCore
import SemanticKernelAbstractions

public struct TimePlugin: SKPlugin {
    public static let pluginName = "time"
    public init() {}

    public func register(with kernel: Kernel) async {
        let nowMeta = KernelFunctionMetadata(
            description: "Get the current time in ISO-8601 format",
            parameters: [ParameterMetadata(name: "offset", type: "Double", description: "Seconds offset from now", required: false)],
            returnType: "String")
        await kernel.registerFunction("\(Self.pluginName).now", metadata: nowMeta) { args in
            let offset = args["offset"].flatMap { Double($0) } ?? 0
            let date = Date().addingTimeInterval(offset)
            let formatter = ISO8601DateFormatter()
            return KernelResult(formatter.string(from: date))
        }
        
        let todayMeta = KernelFunctionMetadata(
            description: "Get today's date in human-readable format",
            parameters: [],
            returnType: "String")
        await kernel.registerFunction("\(Self.pluginName).today", metadata: todayMeta) { args in
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .none
            return KernelResult(formatter.string(from: Date()))
        }
    }
}
