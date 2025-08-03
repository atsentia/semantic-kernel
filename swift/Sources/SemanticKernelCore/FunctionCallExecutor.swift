import Foundation
import SemanticKernelAbstractions

public struct FunctionCallExecutor {
    let kernel: Kernel
    public init(kernel: Kernel) { self.kernel = kernel }

    public func handle(messages: [ChatMessage], toolCalls: [ToolCall]) async -> [ChatMessage] {
        var result = messages
        for call in toolCalls {
            var argsDict: [String: String] = [:]
            if let data = call.arguments.data(using: .utf8),
               let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                for (k,v) in obj {
                    switch v {
                    case let s as String: argsDict[k] = s
                    case let b as Bool: argsDict[k] = b ? "true" : "false"
                    case let i as Int: argsDict[k] = String(i)
                    case let d as Double: argsDict[k] = String(d)
                    default: argsDict[k] = String(describing: v)
                    }
                }
            }
            if let meta = await kernel.metadata(for: call.name) {
                let missing = meta.parameters.filter { $0.required && argsDict[$0.name] == nil }.map { $0.name }
                if !missing.isEmpty {
                    result.append(ChatMessage(role: .assistant, content: "Error: missing arguments: \(missing.joined(separator: ","))"))
                    continue
                }
            }
            do {
                let res = try await kernel.run(functionName: call.name, arguments: KernelArguments(argsDict))
                result.append(ChatMessage(role: .tool, content: res.output, toolCallId: call.id))
            } catch {
                result.append(ChatMessage(role: .tool, content: "Error: \(error)", toolCallId: call.id))
            }
        }
        return result
    }
}
