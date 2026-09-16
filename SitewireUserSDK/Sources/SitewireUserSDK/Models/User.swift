import Foundation

/// API response model for user data
public struct User: Codable, Identifiable, Equatable, Sendable {
    public let id: Int
    public let firstName: String
    public let lastName: String
    public let email: String

    public var fullName: String {
        "\(firstName) \(lastName)"
    }

    public init(id: Int, firstName: String, lastName: String, email: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
    }
}
