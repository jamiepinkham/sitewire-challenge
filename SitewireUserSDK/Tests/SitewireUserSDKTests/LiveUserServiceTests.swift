import XCTest
@testable import SitewireUserSDK

final class LiveUserServiceTests: XCTestCase {

    // MARK: - Test Data

    private let testUsers = [
        User(id: 2, firstName: "Jane", lastName: "Smith", email: "jane@example.com"),
        User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com"),
        User(id: 3, firstName: "Bob", lastName: "Johnson", email: "bob@example.com")
    ]

    private func makeLoginHistory(userId: Int, loginCount: Int = 1) -> LoginHistory {
        let logins = (1...loginCount).map { i in
            LoginHistory.Login(
                loginTime: "2026-09-\(String(format: "%02d", i))T10:00:00Z",
                ipV4: "192.168.1.\(i)"
            )
        }
        return LoginHistory(userId: userId, logins: logins)
    }

    // MARK: - Success Tests

    func testFetchAllUsersSuccess() async throws {
        let session = MockURLSession()

        // Register users response
        session.registerResponse(
            for: "https://fake-users-api.vercel.app/users",
            statusCode: 200,
            data: try JSONEncoder().encode(testUsers)
        )

        // Register login history responses for each user
        for user in testUsers {
            let loginHistory = makeLoginHistory(userId: user.id, loginCount: 2)
            session.registerResponse(
                for: "https://fake-users-api.vercel.app/users/\(user.id)/logs",
                statusCode: 200,
                data: try JSONEncoder().encode(loginHistory)
            )
        }

        let client = LiveUsersAPIClient(session: session)
        let service = LiveUserService(apiClient: client)

        let userData = try await service.fetchAllUsers()

        // Verify all users were fetched
        XCTAssertEqual(userData.count, 3)

        // Verify results are sorted by user ID
        XCTAssertEqual(userData[0].user.id, 1)
        XCTAssertEqual(userData[1].user.id, 2)
        XCTAssertEqual(userData[2].user.id, 3)

        // Verify login data was included
        XCTAssertEqual(userData[0].logins.count, 2)
        XCTAssertEqual(userData[1].logins.count, 2)
        XCTAssertEqual(userData[2].logins.count, 2)
    }

    func testFetchAllUsersWithEmptyLogins() async throws {
        let session = MockURLSession()

        let singleUser = [User(id: 1, firstName: "Test", lastName: "User", email: "test@example.com")]

        session.registerResponse(
            for: "https://fake-users-api.vercel.app/users",
            statusCode: 200,
            data: try JSONEncoder().encode(singleUser)
        )

        let emptyLoginHistory = LoginHistory(userId: 1, logins: [])
        session.registerResponse(
            for: "https://fake-users-api.vercel.app/users/1/logs",
            statusCode: 200,
            data: try JSONEncoder().encode(emptyLoginHistory)
        )

        let client = LiveUsersAPIClient(session: session)
        let service = LiveUserService(apiClient: client)

        let userData = try await service.fetchAllUsers()

        XCTAssertEqual(userData.count, 1)
        XCTAssertEqual(userData[0].logins.count, 0)
    }

    func testSortingByUserId() async throws {
        let session = MockURLSession()

        // Users returned in random order
        let unsortedUsers = [
            User(id: 5, firstName: "E", lastName: "User", email: "e@example.com"),
            User(id: 2, firstName: "B", lastName: "User", email: "b@example.com"),
            User(id: 8, firstName: "H", lastName: "User", email: "h@example.com"),
            User(id: 1, firstName: "A", lastName: "User", email: "a@example.com")
        ]

        session.registerResponse(
            for: "https://fake-users-api.vercel.app/users",
            statusCode: 200,
            data: try JSONEncoder().encode(unsortedUsers)
        )

        for user in unsortedUsers {
            let loginHistory = makeLoginHistory(userId: user.id)
            session.registerResponse(
                for: "https://fake-users-api.vercel.app/users/\(user.id)/logs",
                statusCode: 200,
                data: try JSONEncoder().encode(loginHistory)
            )
        }

        let client = LiveUsersAPIClient(session: session)
        let service = LiveUserService(apiClient: client)

        let userData = try await service.fetchAllUsers()

        // Verify sorting
        XCTAssertEqual(userData.map { $0.user.id }, [1, 2, 5, 8])
    }

    // MARK: - Error Propagation Tests

    func testErrorPropagationFromUsersFetch() async {
        let session = MockURLSession()

        session.registerError(
            for: "https://fake-users-api.vercel.app/users",
            error: URLError(.notConnectedToInternet)
        )

        let client = LiveUsersAPIClient(session: session)
        let service = LiveUserService(apiClient: client)

        do {
            _ = try await service.fetchAllUsers()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .allRetriesFailed = error {
                // Expected
            } else {
                XCTFail("Expected allRetriesFailed error")
            }
        }
    }

    func testErrorPropagationFromLoginsFetch() async {
        let session = MockURLSession()

        let singleUser = [User(id: 1, firstName: "Test", lastName: "User", email: "test@example.com")]

        session.registerResponse(
            for: "https://fake-users-api.vercel.app/users",
            statusCode: 200,
            data: try JSONEncoder().encode(singleUser)
        )

        // Login fetch fails
        session.registerError(
            for: "https://fake-users-api.vercel.app/users/1/logs",
            error: URLError(.notConnectedToInternet)
        )

        let client = LiveUsersAPIClient(session: session)
        let service = LiveUserService(apiClient: client)

        do {
            _ = try await service.fetchAllUsers()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .allRetriesFailed = error {
                // Expected - error from login fetch should propagate
            } else {
                XCTFail("Expected allRetriesFailed error")
            }
        }
    }

    // MARK: - Custom Base URL Tests

    func testCustomBaseURL() async throws {
        let customURL = "https://custom-api.example.com"
        let session = MockURLSession()

        session.registerResponse(
            for: "\(customURL)/users",
            statusCode: 200,
            data: try JSONEncoder().encode(testUsers)
        )

        for user in testUsers {
            let loginHistory = makeLoginHistory(userId: user.id)
            session.registerResponse(
                for: "\(customURL)/users/\(user.id)/logs",
                statusCode: 200,
                data: try JSONEncoder().encode(loginHistory)
            )
        }

        let client = LiveUsersAPIClient(baseURL: customURL, session: session)
        let service = LiveUserService(apiClient: client)

        let userData = try await service.fetchAllUsers()

        XCTAssertEqual(userData.count, 3)
    }
}
