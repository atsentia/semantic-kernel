import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct PluginTest {
    static func main() async {
        print("🧪 Testing Semantic Kernel Plugin Integration...")
        
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
            
            // Test 1: Math Plugin
            print("\n📊 Testing Math Plugin...")
            await testMathPlugin(kernel: kernel)
            
            // Test 2: Text Plugin  
            print("\n📝 Testing Text Plugin...")
            await testTextPlugin(kernel: kernel)
            
            // Test 3: Time Plugin
            print("\n⏰ Testing Time Plugin...")
            await testTimePlugin(kernel: kernel)
            
            // Test 4: Plugin function calling via AI
            print("\n🤖 Testing AI Plugin Function Calling...")
            await testAIPluginCalling(kernel: kernel)
            
        } catch {
            print("❌ FAILED: Error during testing: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🎉 Plugin integration test completed!")
    }
    
    static func testMathPlugin(kernel: Kernel) async {
        do {
            // Test addition
            let addResult = try await kernel.run(
                functionName: "math.add", 
                arguments: KernelArguments(["x": "25", "y": "17"])
            )
            print("✅ Math Add: \(addResult)")
            
            // Test multiplication
            let multiplyResult = try await kernel.run(
                functionName: "math.multiply", 
                arguments: KernelArguments(["x": "8", "y": "7"])
            )
            print("✅ Math Multiply: \(multiplyResult)")
            
        } catch {
            print("❌ Math Plugin Error: \(error)")
        }
    }
    
    static func testTextPlugin(kernel: Kernel) async {
        do {
            // Test uppercase
            let upperResult = try await kernel.run(
                functionName: "text.upper", 
                arguments: KernelArguments(["input": "hello world"])
            )
            print("✅ Text Uppercase: \(upperResult)")
            
            // Test length
            let lengthResult = try await kernel.run(
                functionName: "text.length", 
                arguments: KernelArguments(["input": "The quick brown fox jumps"])
            )
            print("✅ Text Length: \(lengthResult)")
            
        } catch {
            print("❌ Text Plugin Error: \(error)")
        }
    }
    
    static func testTimePlugin(kernel: Kernel) async {
        do {
            // Test current time
            let timeResult = try await kernel.run(
                functionName: "time.now", 
                arguments: KernelArguments()
            )
            print("✅ Time Now: \(timeResult)")
            
        } catch {
            print("❌ Time Plugin Error: \(error)")
        }
    }
    
    static func testAIPluginCalling(kernel: Kernel) async {
        guard let chatService: ChatCompletionService = await kernel.getService() else {
            print("❌ Chat service not available")
            return
        }
        
        do {
            // Test if AI can call math functions
            let mathQuery = "Calculate 15 + 27 using the math plugin"
            let systemMessage = SemanticKernelAbstractions.ChatMessage(
                role: .system,
                content: "You have access to Math, Text, and Time plugins. When asked to perform calculations, dates, or text operations, use the appropriate plugin functions. Available functions: MathPlugin.add, MathPlugin.multiply, TextPlugin.uppercase, TextPlugin.length, TimePlugin.now, TimePlugin.today"
            )
            
            let userMessage = SemanticKernelAbstractions.ChatMessage(
                role: .user,
                content: mathQuery
            )
            
            let chatHistory = [systemMessage, userMessage]
            let settings = CompletionSettings(temperature: 0.1, maxTokens: 200)
            
            let result = try await chatService.generateMessage(history: chatHistory, settings: settings)
            print("✅ AI Math Response: \(result.content)")
            
            // Test if AI can call time functions
            let timeQuery = "What is today's date using the time plugin?"
            let timeUserMessage = SemanticKernelAbstractions.ChatMessage(
                role: .user,
                content: timeQuery
            )
            
            let timeHistory = [systemMessage, timeUserMessage]
            let timeResult = try await chatService.generateMessage(history: timeHistory, settings: settings)
            print("✅ AI Time Response: \(timeResult.content)")
            
        } catch {
            print("❌ AI Plugin Calling Error: \(error)")
        }
    }
}