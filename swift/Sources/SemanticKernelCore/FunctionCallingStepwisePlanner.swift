import Foundation
import SemanticKernelAbstractions

public struct PlannerOptions: Sendable {
    public var maxSteps: Int
    public var maxTokens: Int?
    public var stopOnNoOp: Bool
    public var memoryRecall: Bool

    public init(maxSteps: Int = 5, maxTokens: Int? = nil, stopOnNoOp: Bool = true, memoryRecall: Bool = false) {
        self.maxSteps = maxSteps
        self.maxTokens = maxTokens
        self.stopOnNoOp = stopOnNoOp
        self.memoryRecall = memoryRecall
    }
}

public struct PlanStep: Sendable {
    public let toolCalls: [ToolCall]?
    public let response: ChatMessage
}

public struct Plan: Sendable {
    public var steps: [PlanStep] = []
    public var finalAnswer: String?
}

public struct FunctionCallingStepwisePlanner: Sendable {
    let kernel: Kernel
    let options: PlannerOptions

    public init(kernel: Kernel, options: PlannerOptions = PlannerOptions()) {
        self.kernel = kernel
        self.options = options
    }

    public func execute(goal: String, history: [ChatMessage] = []) async throws -> Plan {
        var plan = Plan()
        var messages = history
        
        // Add system prompt to guide function calling behavior
        if messages.isEmpty || messages.first?.role != .system {
            let systemPrompt = """
            You are a helpful assistant with access to functions. When a user asks a question:
            1. If you need to call a function to get information, call the appropriate function
            2. After getting the function result, provide a clear, conversational answer to the user
            3. Do not call the same function multiple times unless the user asks for a different calculation
            4. Always provide a final answer in natural language after using functions
            """
            messages.insert(ChatMessage(role: .system, content: systemPrompt), at: 0)
        }
        
        messages.append(ChatMessage(role: .user, content: goal))
        guard let service: ChatCompletionService = await kernel.getService() else {
            throw KernelError.serviceNotFound("ChatCompletionService")
        }
        let executor = FunctionCallExecutor(kernel: kernel)
        for stepIndex in 0..<options.maxSteps {
            try Task.checkCancellation()
            // Get available function schemas from the kernel
            let functions = await kernel.exportFunctionSchemas()
            
            // Try to use the function-aware method if available, fallback to standard method
            let msg: ChatMessage
            if let functionAwareService = service as? FunctionAwareChatCompletionService {
                msg = try await functionAwareService.generateMessage(
                    history: messages,
                    settings: CompletionSettings(maxTokens: options.maxTokens ?? 1000),
                    functions: functions.isEmpty ? nil : functions
                )
            } else {
                msg = try await service.generateMessage(history: messages, settings: CompletionSettings(maxTokens: options.maxTokens ?? 1000))
            }
            plan.steps.append(PlanStep(toolCalls: msg.toolCalls, response: msg))
            kernel.log.debug("planner step \(stepIndex)", metadata: ["calls": "\(msg.toolCalls?.count ?? 0)"])
            if let calls = msg.toolCalls, !calls.isEmpty {
                // First add the assistant message with tool calls to the conversation
                messages.append(msg)
                // Then handle the tool calls and add function results
                messages = await executor.handle(messages: messages, toolCalls: calls)
                if options.stopOnNoOp && calls.isEmpty { break }
                continue
            } else {
                messages.append(msg)
                plan.finalAnswer = msg.content
                break
            }
        }
        return plan
    }
}

public actor ChatAgent {
    private let planner: FunctionCallingStepwisePlanner
    private var history: [ChatMessage] = []

    public init(planner: FunctionCallingStepwisePlanner) {
        self.planner = planner
    }

    public func send(_ input: String) async throws -> String {
        try Task.checkCancellation()
        let plan = try await planner.execute(goal: input, history: history)
        history.append(ChatMessage(role: .user, content: input))
        if let answer = plan.finalAnswer {
            history.append(ChatMessage(role: .assistant, content: answer))
            return answer
        }
        return ""
    }
}
