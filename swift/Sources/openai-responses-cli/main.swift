import Foundation
import SemanticKernelConnectorsOpenAI

@main
struct OpenAIResponsesCLI {
    static func main() async {
        let topic = CommandLine.arguments.dropFirst().first ?? "swift programming"
        let service = OpenAIResponsesService()
        do {
            let data = try await service.response(for: topic)
            if let json = try? JSONSerialization.jsonObject(with: data) {
                let pretty = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .withoutEscapingSlashes])
                if let str = String(data: pretty, encoding: .utf8) {
                    print(str)
                }
            } else if let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } catch {
            let msg = "Error: \(error)\n"
            if let data = msg.data(using: .utf8) {
                if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
                    try? FileHandle.standardError.write(contentsOf: data)
                } else {
                    FileHandle.standardError.write(data)
                }
            }
        }
    }
}
