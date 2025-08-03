import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct ModelComparisonTest {
    static func main() async {
        print("🔬 Testing Time Plugin Function Calling Across Different Models...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        let models = ["gpt-4o-mini", "gpt-4", "gpt-4o"]
        
        for model in models {
            print("\n" + String(repeating: "=", count: 50))
            print("🤖 Testing model: \(model)")
            print(String(repeating: "=", count: 50))
            
            do {
                // Create kernel with specific model
                var builder = KernelBuilder()
                let chatService = OpenAIChatCompletionService(
                    apiKey: apiKey,
                    model: model,
                    httpClient: httpClient
                )
                builder = await builder.withService(chatService as ChatCompletionService)
                builder = builder.withPlugin(TimePlugin())
                
                let kernel = await builder.build()
                let planner = FunctionCallingStepwisePlanner(kernel: kernel)
                let agent = ChatAgent(planner: planner)
                
                // Test queries that should trigger time functions
                let timeQueries = [
                    "What time is it?",
                    "Tell me the current time",
                    "Use the time.now function to get the current time",
                    "Call time.now() please",
                    "What's today's date?",
                    "Get today's date using time.today function"
                ]
                
                for query in timeQueries {
                    print("\n📝 Query: \(query)")
                    do {
                        let response = try await agent.send(query)
                        let hasTimeData = response.contains("2025") || response.contains("T") || response.contains(":")
                        let status = hasTimeData ? "✅ LIKELY CALLED" : "❌ NO TIME DATA"
                        print("\(status) Response: \(response)")
                    } catch {
                        print("❌ Error: \(error)")
                    }
                }
                
            } catch {
                print("❌ Error with model \(model): \(error)")
            }
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Model comparison test completed!")
    }
}