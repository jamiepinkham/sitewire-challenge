import Foundation

/// Errors that can occur when interacting with the Vercel Users API
public enum APIError: LocalizedError, Sendable {
    /// Network connectivity error occurred
    case networkError(Error)

    /// Server returned an error status code
    case serverError(statusCode: Int)

    /// Failed to decode the API response
    case decodingError(Error)

    /// All retry attempts failed
    case allRetriesFailed(attempts: Int)

    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let statusCode):
            return "Server error: HTTP \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .allRetriesFailed(let attempts):
            return "Request failed after \(attempts) attempts"
        }
    }
}
