import Foundation
import SemanticKernelAbstractions

extension KernelFunctionMetadata {
    func toFunctionDefinition(name: String) -> FunctionDefinition {
        var props: [String: FunctionDefinition.JSONSchema.Property] = [:]
        var req: [String] = []
        for p in parameters {
            props[p.name] = FunctionDefinition.JSONSchema.Property(type: p.jsonType, description: p.description)
            if p.required { req.append(p.name) }
        }
        let schema = FunctionDefinition.JSONSchema(properties: props, required: req.isEmpty ? nil : req)
        return FunctionDefinition(name: name, description: description, parameters: schema, returns: returnType)
    }
}
