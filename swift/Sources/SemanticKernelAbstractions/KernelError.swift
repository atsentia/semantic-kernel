import Foundation

public enum KernelError: Error {
    case functionNotFound(String)
    case serviceNotFound(String)
    case invalidState(String)
    case missingArgument(String)
}

public enum AIServiceError: Error {
    case unauthorized
    case rateLimited
    case badResponse(status: Int)
    case invalidResponse
}
