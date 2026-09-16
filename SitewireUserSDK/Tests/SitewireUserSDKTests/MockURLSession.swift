import Foundation
@testable import SitewireUserSDK

/// Mock URLSession for testing
final class MockURLSession: URLSession, @unchecked Sendable {
    private var responses: [String: (Data, URLResponse)] = [:]
    private var errors: [String: Error] = [:]
    private var responseGenerators: [String: (URL) -> (Data, URLResponse)] = [:]

    override func data(from url: URL) async throws -> (Data, URLResponse) {
        let urlString = url.absoluteString

        // Check for registered error
        if let error = errors[urlString] {
            throw error
        }

        // Check for response generator
        if let generator = responseGenerators[urlString] {
            return generator(url)
        }

        // Check for static response
        if let response = responses[urlString] {
            return response
        }

        throw URLError(.badURL)
    }

    func registerResponse(for urlString: String, statusCode: Int, data: Data) {
        let url = URL(string: urlString)!
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        responses[urlString] = (data, response)
    }

    func registerError(for urlString: String, error: Error) {
        errors[urlString] = error
    }

    func registerResponseGenerator(for urlString: String, generator: @escaping (URL) -> (Data, URLResponse)) {
        responseGenerators[urlString] = generator
    }
}
