import Foundation
import SemanticKernelAbstractions

public final class FileIOPlugin: KernelPlugin {
    public init() {}

    public var descriptors: [PluginDescriptor] {
        [
            PluginDescriptor(
                name: "readText",
                description: "Read text content from a file path",
                parameters: [ParameterMetadata(name: "path", type: "String", description: "File path")],
                returnType: "String"
            ) { args in
                guard let path = args["path"] else { throw KernelError.invalidState("missing path") }
                let content = try String(contentsOfFile: path, encoding: .utf8)
                return KernelResult(content)
            },
            PluginDescriptor(
                name: "writeText",
                description: "Write text content to a file path",
                parameters: [
                    ParameterMetadata(name: "path", type: "String", description: "File path"),
                    ParameterMetadata(name: "content", type: "String", description: "Content to write")
                ],
                returnType: "String"
            ) { args in
                guard let path = args["path"], let content = args["content"] else { throw KernelError.invalidState("missing parameters") }
                try content.write(toFile: path, atomically: true, encoding: .utf8)
                return KernelResult("ok")
            }
        ]
    }
}
