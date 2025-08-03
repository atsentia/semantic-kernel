// This test suite verifies the functionality of loading and importing plugins within the Semantic Kernel.
import XCTest
import Foundation
@testable import SemanticKernelCore
@testable import SemanticKernelAbstractions

final class SkillLoaderTests: XCTestCase {
    /// A dummy text completion service for testing purposes.
    final class EchoService: TextCompletionService, @unchecked Sendable {
        var lastSettings: CompletionSettings?
        func generateText(prompt: String, settings: CompletionSettings?) async throws -> String {
            lastSettings = settings
            return "ECHO:" + prompt
        }
    }

    /// Helper function to build a dummy plugin at a given URL.
    func buildPlugin(at url: URL, defaultValue: String? = nil, temp: Double? = nil) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try "Hello {{name}}".write(to: url.appendingPathComponent("skprompt.txt"), atomically: true, encoding: .utf8)
        var cfg: [String: Any] = [:]
        var input: [String: Any] = [:]
        var varEntry: [String: Any] = [:]
        if let d = defaultValue { varEntry["default"] = d }
        input["name"] = varEntry
        cfg["input"] = input
        if let t = temp { cfg["completion"] = ["temperature": t] }
        let data = try JSONSerialization.data(withJSONObject: cfg, options: [])
        try data.write(to: url.appendingPathComponent("config.json"))
    }

    /// Tests importing a plugin with a default value for a variable.
    func testImportPluginWithDefault() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("plugin1")
        try? FileManager.default.removeItem(at: tmp)
        try buildPlugin(at: tmp.appendingPathComponent("Echo"), defaultValue: "World")

        let service = EchoService()
        var builder = KernelBuilder()
        builder = await builder.withService(service as TextCompletionService)
        let kernel = await builder.build()
        try await kernel.importSemanticPlugin(at: tmp, named: "test")
        let result = try await kernel.run(functionName: "test.Echo", arguments: KernelArguments())
        XCTAssertEqual(result.output, "ECHO:Hello World")
    }

    /// Tests that a missing variable in a plugin throws the correct error.
    func testMissingVariableError() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("plugin2")
        try? FileManager.default.removeItem(at: tmp)
        try buildPlugin(at: tmp.appendingPathComponent("Echo"))

        let service = EchoService()
        var builder = KernelBuilder()
        builder = await builder.withService(service as TextCompletionService)
        let kernel = await builder.build()
        try await kernel.importSemanticPlugin(at: tmp, named: "test")
        await XCTAssertThrowsErrorAsync(try await kernel.run(functionName: "test.Echo", arguments: KernelArguments())) { error in
            guard case KernelError.missingArgument(let name) = error else { return XCTFail("wrong error") }
            XCTAssertEqual(name, "name")
        }
    }

    /// Tests that model parameters can be overridden when running a plugin.
    func testModelParamOverride() async throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("plugin3")
        try? FileManager.default.removeItem(at: tmp)
        try buildPlugin(at: tmp.appendingPathComponent("Echo"), defaultValue: "Bob", temp: 0.1)

        let service = EchoService()
        var builder = KernelBuilder()
        builder = await builder.withService(service as TextCompletionService)
        let kernel = await builder.build()
        try await kernel.importSemanticPlugin(at: tmp, named: "test")
        let args = KernelArguments(["temperature": "0.7"])
        _ = try await kernel.run(functionName: "test.Echo", arguments: args)
        XCTAssertEqual(service.lastSettings?.temperature, 0.7)
    }
}
