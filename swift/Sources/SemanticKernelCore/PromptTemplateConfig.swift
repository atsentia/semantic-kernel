import Foundation
import SemanticKernelAbstractions

struct PromptTemplateConfig: Decodable {
    struct Completion: Decodable {
        var temperature: Double? = nil
        var max_tokens: Int? = nil
    }

    struct InputVar: Decodable {
        var description: String? = nil
        var defaultValue: String? = nil
        enum CodingKeys: String, CodingKey {
            case description
            case defaultValue = "default"
        }
    }

    var description: String? = nil
    var input: [String: InputVar]? = nil
    var completion: Completion? = nil
}

extension PromptTemplateConfig {
    func defaults() -> [String: String] {
        var result: [String: String] = [:]
        input?.forEach { key, val in
            if let d = val.defaultValue { result[key] = d }
        }
        return result
    }

    func requiredVariables() -> [String] {
        guard let input = input else { return [] }
        return input.compactMap { (name, meta) in
            meta.defaultValue == nil ? name : nil
        }
    }

    func parameters() -> [ParameterMetadata] {
        var params: [ParameterMetadata] = []
        input?.forEach { name, meta in
            params.append(ParameterMetadata(name: name, type: "String", description: meta.description ?? "", required: meta.defaultValue == nil))
        }
        return params
    }

    func settings(overrides: KernelArguments?) -> CompletionSettings? {
        var temp = completion?.temperature
        var maxT = completion?.max_tokens
        if let val = overrides?["temperature"], let d = Double(val) { temp = d }
        if let val = overrides?["maxTokens"], let i = Int(val) { maxT = i }
        if let val = overrides?["max_tokens"], let i = Int(val) { maxT = i }
        if temp == nil && maxT == nil { return nil }
        return CompletionSettings(temperature: temp, maxTokens: maxT)
    }
}
