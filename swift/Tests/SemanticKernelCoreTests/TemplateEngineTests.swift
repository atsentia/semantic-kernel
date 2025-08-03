// This test suite verifies the functionality of the TemplateEngine.
import XCTest
@testable import SemanticKernelCore
@testable import SemanticKernelAbstractions

final class TemplateEngineTests: XCTestCase {
    /// Tests the rendering of variables in a template.
    func testVariables() async throws {
        let kernel = await KernelBuilder().build()
        let result = try await TemplateEngine.render("Hello {{name}}", variables: ["name": "World"], kernel: kernel)
        XCTAssertEqual(result, "Hello World")
    }

    /// Tests the rendering of a loop in a template.
    func testLoop() async throws {
        let kernel = await KernelBuilder().build()
        let template = "{{each x in items}}-{{x}}-{{end}}"
        let result = try await TemplateEngine.render(template, variables: ["items": "a,b"], kernel: kernel)
        XCTAssertEqual(result, "-a--b-")
    }

    /// Tests the rendering of a function call in a template.
    func testFunctionCall() async throws {
        var builder = KernelBuilder()
        builder = builder.withFunction("util.ping") { _ in KernelResult("pong") }
        let kernel = await builder.build()
        let out = try await TemplateEngine.render("Before {{util.ping}} After", variables: [:], kernel: kernel)
        XCTAssertEqual(out, "Before pong After")
    }
}
