import Foundation
import SemanticKernelCore

@main
struct A2ADemo {
    static func main() async throws {
        var builderA = KernelBuilder()
        builderA = builderA.withPluginFunction(plugin: "math", function: mathAddPlugin())
        let kernelA = await builderA.build()

        var builderB = KernelBuilder()
        builderB = builderB.withPluginFunction(plugin: "translator", function: translatePlugin())
        let kernelB = await builderB.build()

        let question = "What is 3 plus 4 in French?"
        print("User -> AgentA: \(question)")
        let mathResult = try await kernelA.call(functionNamed: "add", inPlugin: "math", with: ["a":"3","b":"4"])
        print("AgentA computed: \(mathResult.output)")
        let translated = try await kernelB.call(functionNamed: "translate", inPlugin: "translator", with: ["text": mathResult.output, "lang": "FR"])
        print("AgentB translated: \(translated.output)")
        print("AgentA final answer: \(translated.output)")
    }
}

func mathAddPlugin() -> PluginFunction {
    PluginFunction(name: "add", parameters: ["a","b"], description: "Add two numbers") { params in
        let a = Int(params["a"] ?? "0") ?? 0
        let b = Int(params["b"] ?? "0") ?? 0
        return KernelInvocationResult(String(a+b))
    }
}

func translatePlugin() -> PluginFunction {
    PluginFunction(name: "translate", parameters: ["text","lang"], description: "Very naive translator") { params in
        let text = params["text"] ?? ""
        let lang = (params["lang"] ?? "EN").uppercased()
        if lang == "FR" {
            return KernelInvocationResult("\(text) en francais")
        }
        return KernelInvocationResult("\(text) in \(lang)")
    }
}
