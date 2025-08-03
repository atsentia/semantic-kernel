import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct DebugPlannerTest {
    static func main() async {
        print("🔍 Debugging FunctionCallingStepwisePlanner behavior...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            var builder = KernelBuilder()
            let chatService = OpenAIChatCompletionService(
                apiKey: apiKey,
                model: "gpt-4",
                httpClient: httpClient
            )
            builder = await builder.withService(chatService as ChatCompletionService)
            builder = builder.withPlugin(MathPlugin())
            
            let kernel = await builder.build()
            print("✅ Kernel initialized with MathPlugin")
            
            // Test the planner step by step
            let planner = FunctionCallingStepwisePlanner(kernel: kernel)
            let testQuery = "What is 15 + 27?"
            
            print("\n🔧 Executing planner for: '\(testQuery)'")
            let plan = try await planner.execute(goal: testQuery)
            
            print("\n📊 Plan Analysis:")
            print("   Steps count: \(plan.steps.count)")
            print("   Final answer: '\(plan.finalAnswer ?? "nil")'")
            
            for (index, step) in plan.steps.enumerated() {
                print("\n   Step \(index + 1):")
                print("     Tool calls: \(step.toolCalls?.count ?? 0)")
                if let calls = step.toolCalls {
                    for call in calls {
                        print("       - \(call.name)(\(call.arguments))")
                    }
                }
                print("     Response content: '\(step.response.content)'")
                print("     Response length: \(step.response.content.count) characters")
            }
            
            print("\n🎯 Expected behavior:")
            print("   1. Step 1 should have tool call for math.add(15, 27)")
            print("   2. Step 2 should have final answer with result")
            print("   3. Final answer should contain '42' or similar")
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Debug planner test completed!")
    }
}