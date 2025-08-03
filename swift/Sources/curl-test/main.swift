import Foundation
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct CurlTest {
    static func main() async {
        print("🔧 Testing OpenAI Chat Completions (following curl example)...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            // Create exact request structure from your curl example
            let requestBody = [
                "model": "gpt-4o-mini",  // Use available model
                "messages": [
                    [
                        "role": "system",
                        "content": "You are a helpful assistant."
                    ],
                    [
                        "role": "user", 
                        "content": "What is 2 + 2?"
                    ]
                ],
                "temperature": 1,
                "max_completion_tokens": 100
            ] as [String: Any]
            
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            var request = HTTPClientRequest(url: "https://api.openai.com/v1/chat/completions")
            request.method = .POST
            request.headers.add(name: "Content-Type", value: "application/json")
            request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
            request.body = .bytes(jsonData)
            
            print("📡 Making chat completion request...")
            let response = try await httpClient.execute(request, timeout: .seconds(60))
            
            print("✅ Response status: \(response.status)")
            
            let body = try await response.body.collect(upTo: 1024 * 1024) // 1MB limit
            let bodyString = String(buffer: body)
            
            if let data = bodyString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                print("✅ Response content: '\(content)'")
            } else {
                print("⚠️ Raw response: \(bodyString)")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Curl test completed!")
    }
}