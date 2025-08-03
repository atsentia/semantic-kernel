import Foundation
import SemanticKernelCore
import SemanticKernelAbstractions

public struct TextPlugin: SKPlugin {
    public static let pluginName = "text"
    public init() {}

    public func register(with kernel: Kernel) async {
        let upMeta = KernelFunctionMetadata(
            description: "Convert text to upper case",
            parameters: [ParameterMetadata(name: "input", type: "String", description: "Text to convert")],
            returnType: "String")
        await kernel.registerFunction("\(Self.pluginName).upper", metadata: upMeta) { args in
            let text = args["input"] ?? ""
            return KernelResult(text.uppercased())
        }

        let lowMeta = KernelFunctionMetadata(
            description: "Convert text to lower case",
            parameters: [ParameterMetadata(name: "input", type: "String", description: "Text to convert")],
            returnType: "String")
        await kernel.registerFunction("\(Self.pluginName).lower", metadata: lowMeta) { args in
            let text = args["input"] ?? ""
            return KernelResult(text.lowercased())
        }

        let lenMeta = KernelFunctionMetadata(
            description: "Get length of text",
            parameters: [ParameterMetadata(name: "input", type: "String", description: "Text to measure")],
            returnType: "Int")
        await kernel.registerFunction("\(Self.pluginName).length", metadata: lenMeta) { args in
            let text = args["input"] ?? ""
            return KernelResult(String(text.count))
        }
    }
}
