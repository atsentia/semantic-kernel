// This file contains extensions to XCTestCase for asynchronous error testing.
import XCTest

extension XCTestCase {
    /// Asserts that an asynchronous expression throws an error.
    /// - Parameters:
    ///   - expression: The asynchronous expression to evaluate.
    ///   - message: A closure that receives the thrown error for further assertions.
    func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure @escaping () async throws -> T, _ message: @escaping (Error) -> Void) async {
        do {
            _ = try await expression()
            XCTFail("did not throw")
        } catch {
            message(error)
        }
    }
}
