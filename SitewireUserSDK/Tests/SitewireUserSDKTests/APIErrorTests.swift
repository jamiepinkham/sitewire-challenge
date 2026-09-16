import XCTest
@testable import SitewireUserSDK

final class APIErrorTests: XCTestCase {

    func testNetworkErrorDescription() {
        let error = APIError.networkError(URLError(.notConnectedToInternet))
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network error") ?? false)
    }

    func testServerErrorDescription() {
        let error = APIError.serverError(statusCode: 500)
        XCTAssertEqual(error.errorDescription, "Server error: HTTP 500")
    }

    func testDecodingErrorDescription() {
        struct DummyError: Error, LocalizedError {
            var errorDescription: String? { "Dummy decoding error" }
        }

        let error = APIError.decodingError(DummyError())
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Failed to decode") ?? false)
    }

    func testAllRetriesFailedDescription() {
        let error = APIError.allRetriesFailed(attempts: 3)
        XCTAssertEqual(error.errorDescription, "Request failed after 3 attempts")
    }
}
