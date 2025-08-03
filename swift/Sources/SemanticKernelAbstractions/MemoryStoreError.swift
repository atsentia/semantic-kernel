import Foundation

public enum MemoryStoreError: Error {
    case unauthorized
    case badResponse(status: Int)
    case invalidResponse
}
