// This test suite verifies the generation and execution of function schemas.
import XCTest
@testable import SemanticKernelCore
@testable import SemanticKernelPluginsCore
@testable import SemanticKernelAbstractions

final class FunctionSchemaTests: XCTestCase {
    /// Tests the generation of function schemas from registered plugins.
    func testSchemaGeneration() async throws {
        var builder = KernelBuilder()
        builder = builder.withPlugin(MathPlugin())
        let kernel = await builder.build()
        let defs = await kernel.exportFunctionSchemas()
        guard let add = defs.first(where: { $0.name == "math.add" }) else {
            return XCTFail("missing schema")
        }
        XCTAssertEqual(add.description, "Add two numbers")
        XCTAssertEqual(add.parameters.properties["x"]?.type, "number")
        XCTAssertEqual(add.parameters.required, ["x", "y"])
        XCTAssertEqual(add.returns, "Double")
    }

    /// Tests the round-trip execution of a function call using the FunctionCallExecutor.
    func testExecutorRoundTrip() async throws {
        var builder = KernelBuilder()
        builder = builder.withPlugin(MathPlugin())
        let kernel = await builder.build()
        let exec = FunctionCallExecutor(kernel: kernel)
        let messages = [ChatMessage(role: .user, content: "calc")]
        let calls = [ToolCall(name: "math.add", arguments: "{\"x\":2,\"y\":3}")]
        let newMsgs = await exec.handle(messages: messages, toolCalls: calls)
        XCTAssertEqual(newMsgs.last?.content, "5.0")
    }

    /// Tests that the FunctionCallExecutor handles missing arguments correctly.
    func testExecutorMissingArgs() async throws {
        var builder = KernelBuilder()
        builder = builder.withPlugin(MathPlugin())
        let kernel = await builder.build()
        let exec = FunctionCallExecutor(kernel: kernel)
        let messages = [ChatMessage(role: .user, content: "calc")]
        let calls = [ToolCall(name: "math.add", arguments: "{\"x\":2}")]
        let newMsgs = await exec.handle(messages: messages, toolCalls: calls)
        XCTAssertTrue(newMsgs.last?.content.contains("missing") ?? false)
    }
}
