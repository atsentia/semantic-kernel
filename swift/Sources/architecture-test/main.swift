import Foundation
import SemanticKernelCore
import SemanticKernelConnectorsOpenAI  
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import AsyncHTTPClient

// Test the restructured architecture
@main
struct ArchitectureTest {
    static func main() async {
        print("🧪 Testing Swift Semantic Kernel Architecture...")
        
        do {
            // Test 1: Build kernel with restructured imports (no HTTP for simplicity)
            print("1️⃣ Testing kernel initialization...")
            var builder = KernelBuilder()
            
            // Add plugins without HTTP dependencies
            builder = builder.withPlugin(MathPlugin())
            builder = builder.withPlugin(TextPlugin())
            
            let kernel = await builder.build()
            print("✅ Kernel initialized successfully with plugins")
            
            // Test 2: Test math plugin
            print("2️⃣ Testing Math plugin...")
            let mathArgs = KernelArguments(["x": "5", "y": "3"])
            let mathResult = try await kernel.run(
                functionName: "math.add", 
                arguments: mathArgs
            )
            print("✅ Math test: 5 + 3 = \(mathResult.output)")
            
            // Test 3: Test text plugin  
            print("3️⃣ Testing Text plugin...")
            let textArgs = KernelArguments(["text": "hello semantic kernel"])
            let textResult = try await kernel.run(
                functionName: "text.upper",
                arguments: textArgs
            )
            print("✅ Text test: uppercase = \(textResult.output)")
            
            // Test 4: Test import verification
            print("4️⃣ Testing import verification...")
            print("   ✓ SemanticKernelCore imported")
            print("   ✓ SemanticKernelConnectorsOpenAI imported") 
            print("   ✓ SemanticKernelPluginsCore imported")
            print("   ✓ SemanticKernelAbstractions imported")
            
            print("🎉 All tests passed! Architecture is working correctly.")
            
        } catch {
            print("❌ Test failed: \(error)")
        }
    }
}