@testable import Currency
import XCTest

final class APIRequestTest: XCTestCase {
    struct MockNetworkConfig: NetworkConfigurable {
        let baseURL: URL = .init(string: "https://mock.apple.com")!
        let headers: [String: String] = [:]
        let queryParameters: [String: String] = [:]
    }
    
    
    func test_whenGivenInvalidURL_thenURLRequestThrowsError() {
        let endpoint = APIEndpoint<String>(path: ":\nInvalid URL",isFullPath: true, method: .get)
        let expectation = XCTestExpectation(description: "Invalid url")

        do {
            _ = try endpoint.urlRequest(with: MockNetworkConfig())
            XCTFail("URLRequest should have thrown an error for invalid URL")
        } catch RequestGenerationError.invalidURL {
            expectation.fulfill()
        } catch {
            XCTFail("Caught an unexpected error type")
        }
        wait(for: [expectation], timeout: 3.0)
    }

}
