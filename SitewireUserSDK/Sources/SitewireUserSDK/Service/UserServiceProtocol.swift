import Foundation

/// Domain model combining user and login data
///
/// Represents a complete user record with their login history.
/// This is the primary data model exposed by the SDK.
public struct UserData: Sendable, Equatable {
    public let user: User
    public let logins: [LoginHistory.Login]
    public let isLoadingLogins: Bool

    public init(user: User, logins: [LoginHistory.Login], isLoadingLogins: Bool = false) {
        self.user = user
        self.logins = logins
        self.isLoadingLogins = isLoadingLogins
    }
}

/// Events emitted during user streaming
public enum UserStreamEvent: Sendable, Equatable {
    /// Total number of users to be fetched (emitted first)
    case totalCount(Int)

    /// A user with their login history
    case user(Result<UserData, APIError>)

    /// Stream completed
    case completed

    public static func == (lhs: UserStreamEvent, rhs: UserStreamEvent) -> Bool {
        switch (lhs, rhs) {
        case (.totalCount(let a), .totalCount(let b)):
            return a == b
        case (.user(.success(let a)), .user(.success(let b))):
            return a == b
        case (.user(.failure), .user(.failure)):
            // Errors are not easily comparable, consider failures equal
            return true
        case (.completed, .completed):
            return true
        default:
            return false
        }
    }
}

/// Abstraction for fetching user data
///
/// This protocol enables testing and decouples UI code from API implementation details.
/// Production code uses `LiveUserService`, while tests can use mock implementations.
///
/// ## Example
///
/// ```swift
/// let service: UserServiceProtocol = LiveUserService()
/// for await event in service.streamUsers() {
///     switch event {
///     case .totalCount(let count):
///         print("Loading \(count) users...")
///     case .user(.success(let userData)):
///         print("Loaded: \(userData.user.fullName)")
///     case .completed:
///         print("Done!")
///     }
/// }
/// ```
public protocol UserServiceProtocol: Sendable {
    /// Streams user loading events
    ///
    /// Emits `.totalCount` first with the number of users to fetch,
    /// then `.user` events as each user's login history completes,
    /// and finally `.completed` when all users are loaded.
    ///
    /// - Returns: AsyncStream of user stream events
    func streamUsers() -> AsyncStream<UserStreamEvent>
}
