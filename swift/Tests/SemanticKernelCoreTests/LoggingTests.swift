// This test suite verifies the logging functionality within the Semantic Kernel.
import XCTest
import Logging
@testable import SemanticKernelCore
@testable import SemanticKernelAbstractions

final class LoggingTests: XCTestCase {
    /// Tests that the kernel logs function invocations.
    func testKernelLogsInvocation() async throws {
        final class CapturingHandler: LogHandler, @unchecked Sendable {
            var metadata: Logger.Metadata = [:]
            var logs: [Logger.Message] = []
            subscript(metadataKey key: String) -> Logger.Metadata.Value? {
                get { metadata[key] }
                set { metadata[key] = newValue }
            }
            func log(level: Logger.Level, message: Logger.Message, metadata: Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
                logs.append(message)
            }
            var logLevel: Logger.Level = .trace
        }
        let handler = CapturingHandler()
        let logger = Logger(label: "test") { _ in handler }
        var builder = KernelBuilder()
        builder = builder.withLogger(logger)
        builder = builder.withFunction("ping") { _ in KernelResult("pong") }
        let kernel = await builder.build()
        _ = try await kernel.run(functionName: "ping", arguments: KernelArguments())
        XCTAssertTrue(handler.logs.contains(where: { $0.description.contains("Invoking kernel function") }))
    }
}
