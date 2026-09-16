import Foundation
import OSLog

/// Internal HTTP client for the Vercel Users API
///
/// Handles low-level networking with retry logic to handle API unreliability.
/// Not exposed outside the package - use `UserServiceProtocol` instead.
struct LiveUsersAPIClient: Sendable {
    private let baseURL: String
    private let session: URLSession
    private let logger = Logger(subsystem: "com.sitewire.sdk", category: "network")

    /// Initialize with custom base URL and session
    /// - Parameters:
    ///   - baseURL: The base URL for the API (default: https://fake-users-api.vercel.app)
    ///   - session: URLSession to use (default: configured session with 5s timeout and connection limit)
    init(
        baseURL: String = "https://fake-users-api.vercel.app",
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        self.session = session ?? {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 10.0
            config.timeoutIntervalForResource = 10.0
            config.httpMaximumConnectionsPerHost = 5 // Limit concurrent connections to API
            return URLSession(configuration: config)
        }()
    }

    /// Fetch all users from the API
    /// - Returns: Array of users
    /// - Throws: APIError if the request fails
    func fetchUsers() async throws(APIError) -> [User] {
        try await fetch(endpoint: "/users")
    }

    /// Fetch login history for a specific user
    /// - Parameter userId: The ID of the user
    /// - Returns: LoginHistory for the user
    /// - Throws: APIError if the request fails
    func fetchUserLogins(userId: Int) async throws(APIError) -> LoginHistory {
        try await fetch(endpoint: "/users/\(userId)/relationships/logins")
    }

    // MARK: - Private

    /// Generic fetch method with retry logic
    private func fetch<T: Decodable>(endpoint: String) async throws(APIError) -> T {
        let maxRetries = 3

        logger.debug("🌐 Fetching \(endpoint, privacy: .public)")

        for attempt in 1...maxRetries {
            do {
                let result: T = try await performRequest(endpoint: endpoint)

                if attempt > 1 {
                    logger.info("✅ Succeeded on attempt \(attempt)/\(maxRetries) for \(endpoint, privacy: .public)")
                }

                return result
            } catch let error {
                logger.warning("⚠️ Attempt \(attempt)/\(maxRetries) failed for \(endpoint, privacy: .public): \(String(describing: error), privacy: .public)")

                // Don't retry on client errors (4xx) or decoding errors
                switch error {
                case .serverError(let statusCode) where statusCode >= 400 && statusCode < 500:
                    logger.error("❌ Client error \(statusCode) - not retrying")
                    throw error
                case .decodingError:
                    logger.error("❌ Decoding error - not retrying")
                    throw error
                default:
                    break // Will retry
                }
            } catch {
                // Network errors - will retry
                logger.warning("⚠️ Network error on attempt \(attempt)/\(maxRetries)")
            }

            // Don't sleep after the last attempt
            if attempt < maxRetries {
                // Exponential backoff: 0.1s, 0.2s, 0.4s
                let delay = 0.1 * pow(2.0, Double(attempt - 1))
                logger.debug("⏳ Waiting \(delay)s before retry...")

                do {
                    try await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                } catch {
                    // Sleep was cancelled, treat as network error
                    logger.info("🚫 Request cancelled during retry delay")
                    throw APIError.networkError(error)
                }
            }
        }

        logger.error("❌ All \(maxRetries) retry attempts failed for \(endpoint, privacy: .public)")
        throw APIError.allRetriesFailed(attempts: maxRetries)
    }

    /// Perform a single HTTP request
    private func performRequest<T: Decodable>(endpoint: String) async throws(APIError) -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.networkError(URLError(.badURL))
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        // Check for server errors
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.serverError(statusCode: httpResponse.statusCode)
        }

        // Decode the response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
