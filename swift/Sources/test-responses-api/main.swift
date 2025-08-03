import Foundation
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct TestResponsesAPI {
    static func main() async {
        print("🧪 Testing OpenAI Responses API availability...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            // Test if /v1/responses endpoint exists
            var request = HTTPClientRequest(url: "https://api.openai.com/v1/responses")
            request.method = .GET
            request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
            
            print("📡 Testing responses endpoint availability...")
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            
            print("✅ Response status: \(response.status)")
            
            let body = try await response.body.collect(upTo: 1024 * 1024)
            let bodyString = String(buffer: body)
            
            if response.status.code == 404 {
                print("❌ Responses API endpoint not available")
                print("💡 This suggests the responses API is not generally available yet")
            } else if response.status.code == 405 {
                print("✅ Responses API endpoint exists (Method Not Allowed for GET)")
                print("💡 Endpoint exists but requires POST method")
            } else {
                print("📄 Response: \(bodyString)")
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Responses API test completed!")
    }
}