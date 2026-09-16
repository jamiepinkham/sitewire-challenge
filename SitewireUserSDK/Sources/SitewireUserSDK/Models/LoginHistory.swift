import Foundation

/// API response model for login history
public struct LoginHistory: Codable, Equatable, Sendable {
    public let userId: Int
    public let logins: [Login]

    public struct Login: Codable, Equatable, Sendable {
        public let loginTime: String  // ISO 8601 format
        public let ipV4: String

        public init(loginTime: String, ipV4: String) {
            self.loginTime = loginTime
            self.ipV4 = ipV4
        }

        enum CodingKeys: String, CodingKey {
            case loginTime = "login_time"
            case ipV4 = "ip_v4"
        }
    }

    public init(userId: Int, logins: [Login]) {
        self.userId = userId
        self.logins = logins
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case logins
    }
}
