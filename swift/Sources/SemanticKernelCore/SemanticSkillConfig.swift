import Foundation
import SemanticKernelAbstractions

struct SemanticSkillConfig: Decodable {
    struct Completion: Decodable {
        var max_tokens: Int?
        var temperature: Double?
    }

    var description: String?
    var completion: Completion?

    func settings() -> CompletionSettings? {
        guard completion != nil else { return nil }
        return CompletionSettings(temperature: completion?.temperature,
                                  maxTokens: completion?.max_tokens)
    }
}

