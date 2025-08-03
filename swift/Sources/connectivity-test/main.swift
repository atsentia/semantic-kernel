import Foundation
import SemanticKernelConnectorsOpenAI
import AsyncHTTPClient

@main
struct ConnectivityTest {
    static func main() async {
        print("🌐 Testing OpenAI API Connectivity...")
        
        guard let apiKey = SemanticKernelConnectorsOpenAI.Environment.apiKey else {
            print("❌ FAILED: Could not load OpenAI API key")
            return
        }
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
        
        do {
            // Test basic model list call
            var request = HTTPClientRequest(url: "https://api.openai.com/v1/models")
            request.method = .GET
            request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
            request.headers.add(name: "Content-Type", value: "application/json")
            
            print("📡 Making basic API call to /v1/models...")
            let response = try await httpClient.execute(request, timeout: .seconds(30))
            
            print("✅ Response status: \(response.status)")
            print("✅ OpenAI API is reachable")
            
            let body = try await response.body.collect(upTo: 1024 * 1024) // 1MB limit
            let bodyString = String(buffer: body)
            
            if bodyString.contains("gpt-4") {
                print("✅ API response contains expected model data")
            } else {
                print("⚠️ Unexpected API response format")
            }
            
        } catch {
            print("❌ Connectivity Error: \(error)")
        }
        
        try? await httpClient.shutdown()
        print("\n🏁 Connectivity test completed!")
    }
}