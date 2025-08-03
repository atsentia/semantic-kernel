// This test suite verifies the functionality of the Stepwise Planner.
import XCTest
@testable import SemanticKernelCore
@testable import SemanticKernelPluginsCore
@testable import SemanticKernelAbstractions

final class StepwisePlannerTests: XCTestCase {
    /// A stub service for chat completion that returns predefined tool calls.
    actor StubService: ChatCompletionService {
        var count = 0
        func generateMessage(history: [ChatMessage], settings: CompletionSettings?) async throws -> ChatMessage {
            count += 1
            switch count {
            case 1:
                return ChatMessage(role: .assistant, content: "", toolCalls: [ToolCall(name: "math.add", arguments: "{\"x\":2,\"y\":2}")])
            case 2:
                return ChatMessage(role: .assistant, content: "", toolCalls: [ToolCall(name: "text.upper", arguments: "{\"input\":\"4\"}")])
            default:
                return ChatMessage(role: .assistant, content: "4")
            }
        }
    }

    /// Tests the planner's ability to execute a sequence of steps involving tool calls.
    func testPlannerLoop() async throws {
        var builder = KernelBuilder()
        builder = await builder.withService(StubService() as ChatCompletionService)
        builder = builder.withPlugin(MathPlugin())
        builder = builder.withPlugin(TextPlugin())
        let kernel = await builder.build()
        let planner = FunctionCallingStepwisePlanner(kernel: kernel, options: PlannerOptions(maxSteps: 5))
        let plan = try await planner.execute(goal: "What is 2+2 then shout it?")
        XCTAssertEqual(plan.finalAnswer, "4")
        XCTAssertEqual(plan.steps.count, 3)
        XCTAssertEqual(plan.steps.first?.toolCalls?.first?.name, "math.add")
    }

    /// Tests the planner's ability to handle cancellation during execution.
    func testPlannerCancellation() async throws {
        actor SlowService: ChatCompletionService {
            func generateMessage(history: [ChatMessage], settings: CompletionSettings?) async throws -> ChatMessage {
                try await Task.sleep(nanoseconds: 500_000_000)
                return ChatMessage(role: .assistant, content: "done")
            }
        }
        var builder = KernelBuilder()
        builder = await builder.withService(SlowService() as ChatCompletionService)
        let kernel = await builder.build()
        let planner = FunctionCallingStepwisePlanner(kernel: kernel)
        let task = Task { try await planner.execute(goal: "hi") }
        try await Task.sleep(nanoseconds: 100_000_000)
        task.cancel()
        do { _ = try await task.value; XCTFail("expected cancel") } catch is CancellationError {}
    }
}
