// This test suite verifies the functionality of various built-in plugins within the Semantic Kernel.
import XCTest
import NIOCore
@testable import SemanticKernelCore
@testable import SemanticKernelPluginsCore
@testable import SemanticKernelAbstractions
@testable import SemanticKernelConnectorsOpenAI

final class PluginsTests: XCTestCase {
    /// Tests the FileIOPlugin's ability to write and read text from a file.
    func testFileIOPlugin() async throws {
        var builder = KernelBuilder()
        builder = builder.withPlugin(FileIOPlugin(), namespace: "file")
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("t.txt")
        var kernel = await builder.build()
        _ = try await kernel.run(functionName: "file.writeText", arguments: KernelArguments(["path": tmp.path, "content": "hi"]))
        let result = try await kernel.run(functionName: "file.readText", arguments: KernelArguments(["path": tmp.path]))
        XCTAssertEqual(result.output, "hi")
    }

    /// Tests the MathPlugin's ability to perform addition and verifies its metadata.
    func testMathPlugin() async throws {
        var builder = KernelBuilder()
        builder = builder.withPlugin(MathPlugin())
        let kernel = await builder.build()
        let result = try await kernel.run(functionName: "math.add", arguments: KernelArguments(["x": "2", "y": "3"]))
        XCTAssertEqual(result.output, "5.0")
        let meta = await kernel.metadata(for: "math.add")
        XCTAssertEqual(meta?.description, "Add two numbers")
    }

    /// Tests the TextPlugin's ability to convert text to uppercase.
    func testTextPlugin() async throws {
        var builder = KernelBuilder()
        builder = builder.withPlugin(TextPlugin())
        let kernel = await builder.build()
        let result = try await kernel.run(functionName: "text.upper", arguments: KernelArguments(["input": "hi"]))
        XCTAssertEqual(result.output, "HI")
    }

    /// Tests the TimePlugin's ability to get the current time.
    func testTimePlugin() async throws {
        var builder = KernelBuilder()
        builder = builder.withPlugin(TimePlugin())
        let kernel = await builder.build()
        let result = try await kernel.run(functionName: "time.now", arguments: KernelArguments(["offset": "0"]))
        XCTAssertFalse(result.output.isEmpty)
    }

    /// Tests the HttpPlugin's ability to perform a GET request.
    func testHttpPluginGet() async throws {
        let body = ByteBuffer(string: "hello")
        let mock = MockHTTPClient(status: .ok, body: body)
        var builder = KernelBuilder()
        builder = builder.withPlugin(HttpPlugin(client: mock), namespace: "http")
        let kernel = await builder.build()
        let result = try await kernel.run(functionName: "http.get", arguments: KernelArguments(["url": "http://example.com"]))
        XCTAssertEqual(result.output, "hello")
    }
}
