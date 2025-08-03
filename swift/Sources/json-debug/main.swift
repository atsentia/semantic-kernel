import SemanticKernelCore
import SemanticKernelPluginsCore
import SemanticKernelAbstractions
import SemanticKernelConnectorsOpenAI
import Foundation

@main
struct JSONDebug {
    static func main() async {
        print("🔍 Debugging OpenAI Function Calling JSON Structure...")
        
        do {
            var builder = KernelBuilder()
            builder = builder.withPlugin(TimePlugin())
            let kernel = await builder.build()
            
            let functions = await kernel.exportFunctionSchemas()
            print("📋 Function schemas exported: \(functions.count)")
            
            // Convert to OpenAI format and inspect
            let tools: [OpenAITool] = functions.map { funcDef in
                let properties = funcDef.parameters.properties.mapValues { prop in
                    OpenAIParameterProperty(type: prop.type, description: prop.description)
                }
                let parameters = OpenAIFunctionParameters(
                    properties: properties,
                    required: funcDef.parameters.required ?? []
                )
                let function = OpenAIFunction(
                    name: funcDef.name,
                    description: funcDef.description,
                    parameters: parameters
                )
                return OpenAITool(function: function)
            }
            
            print("\n🔧 OpenAI Tools JSON:")
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let toolsData = try encoder.encode(tools)
            let toolsJSON = String(data: toolsData, encoding: .utf8) ?? "encoding failed"
            print(toolsJSON)
            
            // Test a simple request structure
            let messages = [OpenAIMessage(role: "user", content: "What time is it?")]
            let request = ChatCompletionRequest(
                model: "gpt-4",
                messages: messages,
                tools: tools,
                tool_choice: .auto
            )
            
            print("\n📨 Complete Request JSON:")
            let requestData = try encoder.encode(request)
            let requestJSON = String(data: requestData, encoding: .utf8) ?? "encoding failed"
            print(requestJSON)
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        print("\n🏁 JSON debug completed!")
    }
}