import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient
import Foundation

@main
struct FunctionCallingDebug {
    static func main() async {
        print("🔍 Debugging Function Calling OpenAI Request Format...")
        
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
            builder = builder.withPlugin(TimePlugin())
            
            let kernel = await builder.build()
            
            // Test 1: Simple message without functions
            print("\n1️⃣ Testing simple message without functions:")
            let simpleHistory = [ChatMessage(role: .user, content: "Hello, how are you?")]
            do {
                let response = try await chatService.generateMessage(history: simpleHistory, settings: nil)
                print("✅ Simple response: \(response.content)")
            } catch {
                print("❌ Simple request failed: \(error)")
            }
            
            // Test 2: Message with function definitions
            print("\n2️⃣ Testing message with function definitions:")
            let functions = await kernel.exportFunctionSchemas()
            print("📋 Available functions: \(functions.count)")
            for function in functions {
                print("  - \(function.name): \(function.description)")
            }
            
            let timeHistory = [ChatMessage(role: .user, content: "What time is it?")]
            do {
                if let openAIService = chatService as? OpenAIChatCompletionService {
                    let response = try await openAIService.generateMessage(
                        history: timeHistory,
                        settings: nil,
                        functions: functions
                    )
                    print("✅ Function-aware response: \(response.content)")
                    print("✅ Tool calls: \(response.toolCalls?.count ?? 0)")
                }
            } catch {
                print("❌ Function-aware request failed: \(error)")
                if let aiError = error as? AIServiceError {
                    print("   Error details: \(aiError)")
                }
            }
            
        } catch {
            print("❌ Setup error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Debug test completed!")
    }
}