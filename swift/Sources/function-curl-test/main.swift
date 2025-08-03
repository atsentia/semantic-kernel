import Foundation
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct FunctionCurlTest {
    static func main() async {
        print("🔧 Testing OpenAI Function Calling (curl style)...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            // Create request with function calling
            let requestBody = [
                "model": "gpt-4o-mini",
                "messages": [
                    [
                        "role": "system",
                        "content": "You are a helpful assistant with access to functions. Use them when needed."
                    ],
                    [
                        "role": "user", 
                        "content": "What is 15 + 27?"
                    ]
                ],
                "tools": [
                    [
                        "type": "function",
                        "function": [
                            "name": "math_add",
                            "description": "Adds two numbers together",
                            "parameters": [
                                "type": "object",
                                "properties": [
                                    "x": [
                                        "type": "number",
                                        "description": "First number"
                                    ],
                                    "y": [
                                        "type": "number", 
                                        "description": "Second number"
                                    ]
                                ],
                                "required": ["x", "y"]
                            ]
                        ]
                    ]
                ],
                "tool_choice": "auto",
                "temperature": 0.1,
                "max_completion_tokens": 500
            ] as [String: Any]
            
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = HTTPClientRequest(url: "https://api.openai.com/v1/chat/completions")
            request.method = .POST
            request.headers.add(name: "Content-Type", value: "application/json")
            request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
            request.body = .bytes(jsonData)
            
            print("📡 Making function calling request...")
            let response = try await httpClient.execute(request, timeout: .seconds(60))
            
            print("✅ Response status: \(response.status)")
            
            let body = try await response.body.collect(upTo: 1024 * 1024) // 1MB limit
            let bodyString = String(buffer: body)
            
            if let data = bodyString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any] {
                
                print("✅ Message content: '\(message["content"] as? String ?? "nil")'")
                
                if let toolCalls = message["tool_calls"] as? [[String: Any]] {
                    print("✅ Tool calls count: \(toolCalls.count)")
                    for (index, call) in toolCalls.enumerated() {
                        if let function = call["function"] as? [String: Any],
                           let name = function["name"] as? String,
                           let arguments = function["arguments"] as? String {
                            print("  Tool call \(index + 1): \(name)(\(arguments))")
                        }
                    }
                } else {
                    print("⚠️ No tool calls found")
                }
            } else {
                print("⚠️ Raw response: \(bodyString)")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Function curl test completed!")
    }
}