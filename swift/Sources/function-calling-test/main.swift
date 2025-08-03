import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct FunctionCallingTest {
    static func main() async {
        print("🔧 Testing Function Calling with Different Approaches...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        var builder = KernelBuilder()
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            let chatService = OpenAIChatCompletionService(
                apiKey: apiKey,
                model: "gpt-4",
                httpClient: httpClient
            )
            builder = await builder.withService(chatService as ChatCompletionService)
            builder = builder.withPlugin(TimePlugin())
            
            let kernel = await builder.build()
            print("✅ Kernel with TimePlugin ready")
            
            // Test 1: Direct function call
            print("\n1️⃣ Direct function call:")
            let directResult = try await kernel.run(functionName: "time.now", arguments: KernelArguments())
            print("✅ time.now() = \(directResult)")
            
            let todayResult = try await kernel.run(functionName: "time.today", arguments: KernelArguments())
            print("✅ time.today() = \(todayResult)")
            
            // Test 2: ChatAgent with explicit instruction
            print("\n2️⃣ ChatAgent with explicit function calling instruction:")
            let planner = FunctionCallingStepwisePlanner(kernel: kernel)
            let agent = ChatAgent(planner: planner)
            
            let explicitQuery = "Use the time.now function to tell me what time it is right now."
            let explicitResponse = try await agent.send(explicitQuery)
            print("✅ Explicit query response: \(explicitResponse)")
            
            // Test 3: ChatAgent with natural query
            print("\n3️⃣ ChatAgent with natural time query:")
            let naturalQuery = "What time is it?"
            let naturalResponse = try await agent.send(naturalQuery)
            print("✅ Natural query response: \(naturalResponse)")
            
            // Test 4: Check available functions
            print("\n4️⃣ Listing all available functions:")
            // We'll manually check what functions are registered
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Function calling test completed!")
    }
}