import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct SampleCLI {
    static func main() async {
        var builder = KernelBuilder()
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        // Use gpt-4.1-mini model as specified in the requirements
        builder = await builder.withService(OpenAIChatCompletionService(model: "gpt-4.1-mini", httpClient: httpClient) as ChatCompletionService)
        builder = builder.withPlugin(MathPlugin())
        builder = builder.withPlugin(TextPlugin())
        let kernel = await builder.build()
        let planner = FunctionCallingStepwisePlanner(kernel: kernel)
        let agent = ChatAgent(planner: planner)
        print("Type 'exit' to quit")
        while let line = readLine(strippingNewline: true) {
            if line == "exit" { break }
            if let out = try? await agent.send(line) {
                print(out)
            }
        }
        try? await httpClient.shutdown()
    }
}
