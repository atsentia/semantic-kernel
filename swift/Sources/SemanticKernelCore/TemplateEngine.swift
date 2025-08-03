import Foundation
import SemanticKernelAbstractions

/// Lightweight template engine supporting variable replacement, simple loops and
/// kernel function calls. The syntax is a small subset of the Semantic Kernel
/// prompt template language:
///  - Variables: `{{name}}`
///  - Function calls: `{{plugin.function}}`
///  - Loops (not nestable): `{{each item in items}} ... {{end}}`
/// Collections for loops are provided as comma or newline separated strings.
struct TemplateEngine {
    /// Render a template using the provided variables and kernel.
    /// - Parameters:
    ///   - template: Template text containing tokens.
    ///   - variables: Variables available for replacement.
    ///   - kernel: Kernel used to invoke function call tokens.
    static func render(_ template: String, variables: [String: String], kernel: Kernel) async throws -> String {
        // first resolve loops (no nesting support)
        var result = template
        let loopPattern = #"\{\{\s*each\s+([a-zA-Z0-9_]+)\s+in\s+([a-zA-Z0-9_]+)\s*\}\}([\s\S]*?)\{\{\s*end\s*\}\}"#
        let loopRegex = try NSRegularExpression(pattern: loopPattern, options: [.dotMatchesLineSeparators])

        while true {
            guard let match = loopRegex.firstMatch(in: result, range: NSRange(result.startIndex..., in: result)) else {
                break
            }
            guard let itemRange = Range(match.range(at: 1), in: result),
                  let collRange = Range(match.range(at: 2), in: result),
                  let bodyRange = Range(match.range(at: 3), in: result),
                  let fullRange = Range(match.range(at: 0), in: result) else {
                break
            }
            let itemName = String(result[itemRange])
            let collectionName = String(result[collRange])
            let body = String(result[bodyRange])
            let raw = variables[collectionName] ?? ""
            let pieces = raw.split(whereSeparator: { $0 == "," || $0 == "\n" })
            var rendered = ""
            for p in pieces {
                var child = variables
                child[itemName] = p.trimmingCharacters(in: .whitespaces)
                rendered += try await render(body, variables: child, kernel: kernel)
            }
            result.replaceSubrange(fullRange, with: rendered)
        }

        // function call tokens {{plugin.func}}
        let funcPattern = #"\{\{\s*([a-zA-Z0-9_]+\.[a-zA-Z0-9_]+)\s*\}\}"#
        let funcRegex = try NSRegularExpression(pattern: funcPattern)
        var funcMatches = funcRegex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        for match in funcMatches.reversed() {
            guard let range = Range(match.range(at: 0), in: result),
                  let nameRange = Range(match.range(at: 1), in: result) else { continue }
            let name = String(result[nameRange])
            let output = try await kernel.run(functionName: name, arguments: KernelArguments(variables)).output
            result.replaceSubrange(range, with: output)
        }

        // variable tokens {{var}}
        let varPattern = #"\{\{\s*([a-zA-Z0-9_]+)\s*\}\}"#
        let varRegex = try NSRegularExpression(pattern: varPattern)
        let varMatches = varRegex.matches(in: result, range: NSRange(result.startIndex..., in: result))
        for match in varMatches.reversed() {
            if let range = Range(match.range(at: 0), in: result),
               let varRange = Range(match.range(at: 1), in: result) {
                let key = String(result[varRange])
                let value = variables[key] ?? ""
                result.replaceSubrange(range, with: value)
            }
        }
        return result
    }
}
