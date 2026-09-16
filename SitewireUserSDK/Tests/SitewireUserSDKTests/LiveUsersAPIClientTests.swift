import XCTest
@testable import SitewireUserSDK

final class LiveUsersAPIClientTests: XCTestCase {

    // MARK: - Test Data

    private let testUsers = [
        User(id: 1, firstName: "John", lastName: "Doe", email: "john@example.com"),
        User(id: 2, firstName: "Jane", lastName: "Smith", email: "jane@example.com")
    ]

    private let testLoginHistory = LoginHistory(
        userId: 1,
        logins: [
            LoginHistory.Login(loginTime: "2026-09-14T10:00:00Z", ipV4: "192.168.1.1")
        ]
    )

    // MARK: - Successful Fetch Tests

    func testFetchUsersSuccess() async throws {
        let session = MockURLSession()
        session.registerResponse(
            for: "https://fake-users-api.vercel.app/users",
            statusCode: 200,
            data: try JSONEncoder().encode(testUsers)
        )

        let client = LiveUsersAPIClient(session: session)
        let users = try await client.fetchUsers()

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users[0].id, 1)
        XCTAssertEqual(users[0].firstName, "John")
    }

    func testFetchUserLoginsSuccess() async throws {
        let session = MockURLSession()
        session.registerResponse(
            for: "https://fake-users-api.vercel.app/users/1/logs",
            statusCode: 200,
            data: try JSONEncoder().encode(testLoginHistory)
        )

        let client = LiveUsersAPIClient(session: session)
        let loginHistory = try await client.fetchUserLogins(userId: 1)

        XCTAssertEqual(loginHistory.userId, 1)
        XCTAssertEqual(loginHistory.logins.count, 1)
        XCTAssertEqual(loginHistory.logins[0].ipV4, "192.168.1.1")
    }

    // MARK: - Error Handling Tests

    func testNetworkError() async {
        let session = MockURLSession()
        session.registerError(
            for: "https://fake-users-api.vercel.app/users",
            error: URLError(.notConnectedToInternet)
        )

        let client = LiveUsersAPIClient(session: session)

        do {
            _ = try await client.fetchUsers()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .allRetriesFailed(let attempts) = error {
                XCTAssertEqual(attempts, 3, "Should retry 3 times")
            } else {
                XCTFail("Expected allRetriesFailed error, got \(error)")
            }
        }
    }

    func testServerError500Retries() async {
        let session = MockURLSession()
        var attempts = 0

        session.registerResponseGenerator(for: "https://fake-users-api.vercel.app/users") { _ in
            attempts += 1
            return (Data(), HTTPURLResponse(
                url: URL(string: "https://fake-users-api.vercel.app/users")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!)
        }

        let client = LiveUsersAPIClient(session: session)

        do {
            _ = try await client.fetchUsers()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .allRetriesFailed = error {
                XCTAssertEqual(attempts, 3, "Should retry 3 times for 500 errors")
            } else {
                XCTFail("Expected allRetriesFailed error, got \(error)")
            }
        }
    }

    func testClientError404DoesNotRetry() async {
        let session = MockURLSession()
        var attempts = 0

        session.registerResponseGenerator(for: "https://fake-users-api.vercel.app/users") { _ in
            attempts += 1
            return (Data(), HTTPURLResponse(
                url: URL(string: "https://fake-users-api.vercel.app/users")!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!)
        }

        let client = LiveUsersAPIClient(session: session)

        do {
            _ = try await client.fetchUsers()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .serverError(let statusCode) = error {
                XCTAssertEqual(statusCode, 404)
                XCTAssertEqual(attempts, 1, "Should not retry on 4xx errors")
            } else {
                XCTFail("Expected serverError, got \(error)")
            }
        }
    }

    func testDecodingErrorDoesNotRetry() async {
        let session = MockURLSession()
        var attempts = 0

        session.registerResponseGenerator(for: "https://fake-users-api.vercel.app/users") { _ in
            attempts += 1
            let invalidJSON = "{ invalid json }".data(using: .utf8)!
            return (invalidJSON, HTTPURLResponse(
                url: URL(string: "https://fake-users-api.vercel.app/users")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!)
        }

        let client = LiveUsersAPIClient(session: session)

        do {
            let _: [User] = try await client.fetchUsers()
            XCTFail("Expected error to be thrown")
        } catch let error as APIError {
            if case .decodingError = error {
                XCTAssertEqual(attempts, 1, "Should not retry on decoding errors")
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        }
    }

    // MARK: - Retry with Success Tests

    func testRetrySucceedsOnSecondAttempt() async throws {
        let session = MockURLSession()
        var attempts = 0

        session.registerResponseGenerator(for: "https://fake-users-api.vercel.app/users") { _ in
            attempts += 1
            if attempts == 1 {
                // First attempt fails
                return (Data(), HTTPURLResponse(
                    url: URL(string: "https://fake-users-api.vercel.app/users")!,
                    statusCode: 500,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            } else {
                // Second attempt succeeds
                let data = try! JSONEncoder().encode(self.testUsers)
                return (data, HTTPURLResponse(
                    url: URL(string: "https://fake-users-api.vercel.app/users")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!)
            }
        }

        let client = LiveUsersAPIClient(session: session)
        let users = try await client.fetchUsers()

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(attempts, 2, "Should succeed on second attempt")
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

        let client = LiveUsersAPIClient(baseURL: customURL, session: session)
        let users = try await client.fetchUsers()

        XCTAssertEqual(users.count, 2)
    }
}
