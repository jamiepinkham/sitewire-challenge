import XCTest
@testable import SitewireUserSDK

final class ModelTests: XCTestCase {

    // MARK: - User Tests

    func testUserCodable() throws {
        let user = User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com")

        let encoder = JSONEncoder()
        let data = try encoder.encode(user)

        let decoder = JSONDecoder()
        let decodedUser = try decoder.decode(User.self, from: data)

        XCTAssertEqual(decodedUser.id, 1)
        XCTAssertEqual(decodedUser.firstName, "John")
        XCTAssertEqual(decodedUser.lastName, "Doe")
        XCTAssertEqual(decodedUser.email, "john@example.com")
    }

    func testUserFullName() {
        let user = User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com")
        XCTAssertEqual(user.fullName, "John Doe")
    }

    func testUserCodingKeys() throws {
        let json = """
        {
            "id": 1,
            "first_name": "John",
            "last_name": "Doe",
            "email": "john@example.com"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let user = try decoder.decode(User.self, from: json)

        XCTAssertEqual(user.firstName, "John")
        XCTAssertEqual(user.lastName, "Doe")
    }

    func testUserEquatable() {
        let user1 = User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com")
        let user2 = User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com")
        let user3 = User(id: 2, firstName: "Jane", lastName: "Smith", email: "jane@example.com")

        XCTAssertEqual(user1, user2)
        XCTAssertNotEqual(user1, user3)
    }

    // MARK: - LoginHistory Tests

    func testLoginHistoryCodable() throws {
        let loginHistory = LoginHistory(
            userId: 1,
            logins: [
                LoginHistory.Login(loginTime: "2026-09-14T10:00:00Z", ipV4: "192.168.1.1")
            ]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(loginHistory)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(LoginHistory.self, from: data)

        XCTAssertEqual(decoded.userId, 1)
        XCTAssertEqual(decoded.logins.count, 1)
        XCTAssertEqual(decoded.logins[0].loginTime, "2026-09-14T10:00:00Z")
        XCTAssertEqual(decoded.logins[0].ipV4, "192.168.1.1")
    }

    func testLoginHistoryCodingKeys() throws {
        let json = """
        {
            "user_id": 1,
            "logins": [
                {
                    "login_time": "2026-09-14T10:00:00Z",
                    "ip_v4": "192.168.1.1"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let loginHistory = try decoder.decode(LoginHistory.self, from: json)

        XCTAssertEqual(loginHistory.userId, 1)
        XCTAssertEqual(loginHistory.logins[0].loginTime, "2026-09-14T10:00:00Z")
        XCTAssertEqual(loginHistory.logins[0].ipV4, "192.168.1.1")
    }

    func testLoginEquatable() {
        let login1 = LoginHistory.Login(loginTime: "2026-09-14T10:00:00Z", ipV4: "192.168.1.1")
        let login2 = LoginHistory.Login(loginTime: "2026-09-14T10:00:00Z", ipV4: "192.168.1.1")
        let login3 = LoginHistory.Login(loginTime: "2026-09-13T10:00:00Z", ipV4: "192.168.1.1")

        XCTAssertEqual(login1, login2)
        XCTAssertNotEqual(login1, login3)
    }

    // MARK: - UserData Tests

    func testUserDataInit() {
        let user = User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com")
        let logins = [
            LoginHistory.Login(loginTime: "2026-09-14T10:00:00Z", ipV4: "192.168.1.1")
        ]

        let userData = UserData(user: user, logins: logins)

        XCTAssertEqual(userData.user.id, 1)
        XCTAssertEqual(userData.logins.count, 1)
    }

    func testUserDataEquatable() {
        let user = User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com")
        let logins = [
            LoginHistory.Login(loginTime: "2026-09-14T10:00:00Z", ipV4: "192.168.1.1")
        ]

        let userData1 = UserData(user: user, logins: logins)
        let userData2 = UserData(user: user, logins: logins)

        XCTAssertEqual(userData1, userData2)
    }
}
