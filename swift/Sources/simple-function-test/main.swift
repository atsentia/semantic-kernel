import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct SimpleFunctionTest {
    static func main() async {
        print("🧪 Simple Function Calling Test...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            var builder = KernelBuilder()
            let chatService = OpenAIChatCompletionService(
                apiKey: apiKey,
                model: "gpt-4o-mini",  // Use faster, cheaper model
                httpClient: httpClient
            )
            builder = await builder.withService(chatService as ChatCompletionService)
            builder = builder.withPlugin(MathPlugin())
            
            let kernel = await builder.build()
            print("✅ Kernel initialized")
            
            // Create agent with shorter timeout
            let plannerOptions = PlannerOptions(maxSteps: 3, maxTokens: 500)
            let planner = FunctionCallingStepwisePlanner(kernel: kernel, options: plannerOptions)
            let agent = ChatAgent(planner: planner)
            
            // Test simple math question
            let testQueries = [
                "What is 15 + 27?",
                "What is 5 times 8?",
                "What is the current date?"
            ]
            
            for query in testQueries {
                print("\n🔧 Testing: '\(query)'")
                let response = try await agent.send(query)
                print("   Response: '\(response)'")
                print("   Length: \(response.count) characters")
                
                if response.isEmpty {
                    print("   ❌ WARNING: Empty response!")
                } else {
                    print("   ✅ Got response")
                }
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Simple function test completed!")
    }
}