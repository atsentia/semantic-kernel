import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct APITest {
    static func main() async {
        print("🔧 Testing OpenAI API integration with .env file...")
        
        // Test 1: Check if API key can be loaded from .env
        print("\n1️⃣ Testing API key loading from .env file...")
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key from .env file")
            print("   Make sure OPENAI_API_KEY is set in .env file")
            return
        }
        print("✅ SUCCESS: API key loaded from .env file (length: \(apiKey.count))")
        
        // Test 2: Initialize kernel with OpenAI service
        print("\n2️⃣ Testing kernel initialization...")
        var builder = KernelBuilder()
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            let chatService = OpenAIChatCompletionService(
                apiKey: apiKey,
                model: "gpt-4",
                httpClient: httpClient
            )
            builder = await builder.withService(chatService as ChatCompletionService)
            builder = builder.withPlugin(MathPlugin())
            builder = builder.withPlugin(TextPlugin())
            
            let kernel = await builder.build()
            print("✅ SUCCESS: Kernel initialized with OpenAI service and plugins")
            
            // Test 3: Verify service can be retrieved
            print("\n3️⃣ Testing service retrieval...")
            guard let retrievedService: ChatCompletionService = await kernel.getService() else {
                print("❌ FAILED: Could not retrieve ChatCompletionService from kernel")
                try? await httpClient.shutdown()
                return
            }
            print("✅ SUCCESS: ChatCompletionService retrieved from kernel")
            
            // Test 4: Test actual API call
            print("\n4️⃣ Testing OpenAI API call...")
            let systemMessage = SemanticKernelAbstractions.ChatMessage(
                role: .system,
                content: "You are a helpful assistant. Respond with exactly 'API test successful' if you receive this message."
            )
            
            let userMessage = SemanticKernelAbstractions.ChatMessage(
                role: .user,
                content: "Please confirm the API test is working."
            )
            
            let chatHistory = [systemMessage, userMessage]
            let settings = CompletionSettings()
            
            let result = try await retrievedService.generateMessage(history: chatHistory, settings: settings)
            print("✅ SUCCESS: OpenAI API call completed")
            print("   Response: \(result.content)")
            
            // Test 5: Test math calculation
            print("\n5️⃣ Testing math calculation through kernel...")
            let mathResult = try await kernel.run(
                functionName: "MathPlugin.add",
                arguments: KernelArguments(["input": "What is 15.5 + 24.3?"])
            )
            print("✅ SUCCESS: Math plugin executed")
            print("   Result: \(mathResult)")
            
        } catch {
            print("❌ FAILED: Error during testing: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🎉 Integration test completed!")
    }
}