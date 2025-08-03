import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct ChatAgentTest {
    static func main() async {
        print("🤖 Testing ChatAgent with Plugin Function Calling...")
        
        // Initialize kernel with plugins
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key from .env file")
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
            
            // Add plugins
            builder = builder.withPlugin(MathPlugin())
            builder = builder.withPlugin(TextPlugin())
            builder = builder.withPlugin(TimePlugin())
            
            let kernel = await builder.build()
            print("✅ Kernel initialized with plugins")
            
            // Create planner and chat agent
            let planner = FunctionCallingStepwisePlanner(kernel: kernel)
            let agent = ChatAgent(planner: planner)
            print("✅ ChatAgent created with FunctionCallingStepwisePlanner")
            
            // Test various queries
            let testQueries = [
                "What is 15 + 27?",
                "Convert 'hello world' to uppercase",
                "What time is it now?",
                "What is today's date?",
                "Calculate the area of a circle with diameter 32 cm"
            ]
            
            for query in testQueries {
                print("\n📝 Query: \(query)")
                do {
                    let response = try await agent.send(query)
                    print("✅ Response: '\(response)'")
                    print("   Response length: \(response.count) characters")
                    
                    // Check if we got actual results
                    if response.isEmpty {
                        print("❌ WARNING: Empty response!")
                    } else if response.count < 5 {
                        print("❌ WARNING: Very short response, likely not a real result")
                    } else {
                        // Check for time patterns, numbers, etc.
                        let hasTimePattern = response.contains("2025") || response.contains("T") || response.contains(":")
                        let hasNumbers = response.rangeOfCharacter(from: .decimalDigits) != nil
                        let hasResults = hasTimePattern || hasNumbers || response.lowercased().contains("hello world")
                        
                        if hasResults {
                            print("✅ Response appears to contain actual function results")
                        } else {
                            print("⚠️  Response may not contain actual function results")
                        }
                    }
                } catch {
                    print("❌ Error: \(error)")
                }
            }
            
        } catch {
            print("❌ FAILED: Error during testing: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🎉 ChatAgent test completed!")
    }
}