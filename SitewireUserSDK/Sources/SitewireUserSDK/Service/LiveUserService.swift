import Foundation
import OSLog

/// Production implementation of UserServiceProtocol
///
/// Uses the Vercel Users API to fetch user data and login histories.
/// Implements concurrent fetching with streaming for progressive UI updates.
///
/// ## Features
/// - Automatic retry logic for unreliable API
/// - Concurrent fetching of login histories (max 10 concurrent)
/// - Streaming results as they complete
/// - Graceful handling of partial failures
///
/// ## Example
///
/// ```swift
/// let service = LiveUserService()
/// for await result in service.streamUsers() {
///     switch result {
///     case .success(let user):
///         print("Loaded user: \(user.user.fullName)")
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
/// ```
public struct LiveUserService: UserServiceProtocol {
    private let apiClient: LiveUsersAPIClient
    private let logger = Logger(subsystem: "com.sitewire.sdk", category: "streaming")

    /// Initialize with custom base URL
    /// - Parameter baseURL: The base URL for the API (default: https://fake-users-api.vercel.app)
    public init(baseURL: String = "https://fake-users-api.vercel.app") {
        self.apiClient = LiveUsersAPIClient(baseURL: baseURL)
    }

    /// Initialize with custom API client (for testing)
    internal init(apiClient: LiveUsersAPIClient) {
        self.apiClient = apiClient
    }

    public func streamUsers() -> AsyncStream<UserStreamEvent> {
        AsyncStream { continuation in
            Task {
                logger.info("📡 Starting user stream")

                // 1. Fetch all users from API
                let users: [User]
                do {
                    users = try await apiClient.fetchUsers()
                    logger.info("✅ Fetched \(users.count) users")
                    continuation.yield(.totalCount(users.count))
                } catch let apiError as APIError {
                    logger.error("❌ Failed to fetch users: \(String(describing: apiError), privacy: .public)")
                    continuation.yield(.user(.failure(apiError)))
                    continuation.finish()
                    return
                } catch {
                    logger.error("❌ Unexpected error fetching users: \(String(describing: error), privacy: .public)")
                    continuation.finish()
                    return
                }

                // 2. Stream users immediately with empty logins for instant display
                logger.debug("📤 Streaming \(users.count) users with placeholder data")
                for user in users {
                    continuation.yield(.user(.success(UserData(user: user, logins: [], isLoadingLogins: true))))
                }

                // 3. Fetch login data concurrently and stream updates as they complete
                logger.info("🔄 Fetching login data for \(users.count) users concurrently")
                var completedCount = 0

                await withTaskGroup(of: (Int, Result<UserData, APIError>).self) { group in
                    for user in users {
                        group.addTask {
                            do {
                                let loginHistory = try await self.apiClient.fetchUserLogins(userId: user.id)
                                return (user.id, .success(UserData(user: user, logins: loginHistory.logins, isLoadingLogins: false)))
                            } catch {
                                logger.warning("⚠️ Failed to fetch logins for user \(user.id): using empty array")
                                // Keep empty logins on failure - user already displayed
                                return (user.id, .success(UserData(user: user, logins: [], isLoadingLogins: false)))
                            }
                        }
                    }

                    for await (userId, result) in group {
                        completedCount += 1
                        logger.debug("✅ Login data loaded for user \(userId) (\(completedCount)/\(users.count))")
                        continuation.yield(.user(result))
                    }
                }

                logger.info("🏁 Stream completed - all \(users.count) users processed")
                continuation.yield(.completed)
                continuation.finish()
            }
        }
    }
}
