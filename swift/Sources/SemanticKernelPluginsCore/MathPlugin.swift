import Foundation
import SemanticKernelCore
import SemanticKernelAbstractions

public struct MathPlugin: SKPlugin {
    public static let pluginName = "math"
    public init() {}

    public func register(with kernel: Kernel) async {
        let addMeta = KernelFunctionMetadata(
            description: "Add two numbers",
            parameters: [
                ParameterMetadata(name: "x", type: "Double", description: "First number"),
                ParameterMetadata(name: "y", type: "Double", description: "Second number")
            ],
            returnType: "Double")
        await kernel.registerFunction("\(Self.pluginName).add", metadata: addMeta) { args in
            guard let xStr = args["x"], let x = Double(xStr),
                  let yStr = args["y"], let y = Double(yStr) else {
                throw KernelError.invalidState("missing or invalid parameters")
            }
            return KernelResult(String(x + y))
        }

        let subMeta = KernelFunctionMetadata(
            description: "Subtract second number from first",
            parameters: [
                ParameterMetadata(name: "x", type: "Double", description: "Minuend"),
                ParameterMetadata(name: "y", type: "Double", description: "Subtrahend")
            ],
            returnType: "Double")
        await kernel.registerFunction("\(Self.pluginName).subtract", metadata: subMeta) { args in
            guard let xStr = args["x"], let x = Double(xStr),
                  let yStr = args["y"], let y = Double(yStr) else {
                throw KernelError.invalidState("missing or invalid parameters")
            }
            return KernelResult(String(x - y))
        }

        let mulMeta = KernelFunctionMetadata(
            description: "Multiply two numbers",
            parameters: [
                ParameterMetadata(name: "x", type: "Double", description: "First factor"),
                ParameterMetadata(name: "y", type: "Double", description: "Second factor")
            ],
            returnType: "Double")
        await kernel.registerFunction("\(Self.pluginName).multiply", metadata: mulMeta) { args in
            guard let xStr = args["x"], let x = Double(xStr),
                  let yStr = args["y"], let y = Double(yStr) else {
                throw KernelError.invalidState("missing or invalid parameters")
            }
            return KernelResult(String(x * y))
        }
    }
}
