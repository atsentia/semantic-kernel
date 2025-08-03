import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct DebugMessagesTest {
    static func main() async {
        print("🔍 Debugging Message Flow in Function Calling...")
        
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
            let executor = FunctionCallExecutor(kernel: kernel)
            
            print("✅ Kernel and executor initialized")
            
            // Step 1: Direct function call test
            print("\n1️⃣ Testing direct function execution:")
            let directResult = try await kernel.run(functionName: "math.add", arguments: KernelArguments(["x": "15", "y": "27"]))
            print("   Direct call result: '\(directResult.output)'")
            
            // Step 2: Test executor message handling
            print("\n2️⃣ Testing FunctionCallExecutor:")
            let toolCall = ToolCall(name: "math.add", arguments: "{\"x\": 15, \"y\": 27}")
            let initialMessages = [ChatMessage(role: .user, content: "What is 15 + 27?")]
            
            let resultMessages = await executor.handle(messages: initialMessages, toolCalls: [toolCall])
            print("   Messages after execution:")
            for (index, msg) in resultMessages.enumerated() {
                print("     Message \(index): role=\(msg.role), content='\(msg.content)'")
            }
            
            // Step 3: Test OpenAI function calling directly
            print("\n3️⃣ Testing OpenAI function calling:")
            let functions = await kernel.exportFunctionSchemas()
            print("   Available functions: \(functions.count)")
            
            if let functionAwareService = chatService as? FunctionAwareChatCompletionService {
                let testMessages = [
                    ChatMessage(role: .system, content: "You are a helpful assistant. Use the available functions to answer questions."),
                    ChatMessage(role: .user, content: "What is 15 + 27?")
                ]
                
                let response = try await functionAwareService.generateMessage(
                    history: testMessages,
                    settings: CompletionSettings(maxTokens: 1000),
                    functions: functions
                )
                
                print("   AI Response:")
                print("     Content: '\(response.content)'")
                print("     Tool calls: \(response.toolCalls?.count ?? 0)")
                if let calls = response.toolCalls {
                    for call in calls {
                        print("       - \(call.name): \(call.arguments)")
                    }
                }
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Debug messages test completed!")
    }
}