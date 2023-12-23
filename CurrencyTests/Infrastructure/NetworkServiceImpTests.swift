@testable import Currency
import XCTest

final class NetworkServiceImpTests: XCTestCase {
    func test_whenDataPassed_thenSuccess() {
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock.apple.com/success")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let mockData = "{\"key\":\"value\"}".data(using: .utf8)!

        let sessionManager = MockNetworkSessionManager(response: mockResponse, data: mockData, error: nil)
        let networkService = DefaultNetworkService(config: MockNetworkConfig(), sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Successful response")

        Task {
            do {
                let result: [String: String] = try await networkService.requestTask(endpoint: EndpointMock(path: "/success", method: .get)).value
                XCTAssertEqual(result["key"], "value")
                expectation.fulfill()
            } catch {
                XCTFail("Expected successful response, received error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenCancelRequest_thenCatchCancelledError() {
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock.apple.com/success")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let mockData = "{\"key\":\"value\"}".data(using: .utf8)!

        let sessionManager = MockNetworkSessionManager(response: mockResponse, data: mockData, error: nil)
        let networkService = DefaultNetworkService(config: MockNetworkConfig(), sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Received cancel request message")
        let task = networkService.requestTask(endpoint: EndpointMock<MockModel>(path: "/success", method: .get))

        Task {
            do {
                _ = try await task.value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .responseFailure(.cancelled):
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }

        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            task.cancel()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenStatusCodeNotIn200_299_thenCatchStatusCodeError() {
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock.apple.com/success")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        let mockData = "{\"key\":\"value\"}".data(using: .utf8)!

        let sessionManager = MockNetworkSessionManager(response: mockResponse, data: mockData, error: nil)
        let networkService = DefaultNetworkService(config: MockNetworkConfig(), sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Received error status code")

        Task {
            do {
                _ = try await networkService.requestTask(endpoint: EndpointMock<[String: String]>(path: "/success", method: .get)).value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case let .responseFailure(.error(statusCode, _)) where statusCode == 500:
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenErrorWithNSURLErrorNotConnectedToInternetReturned_thenCatchReturnNotConnectedError() {
        let notConnectedError = URLError(.notConnectedToInternet)
        let sessionManager = MockNetworkSessionManager(response: nil, data: nil, error: notConnectedError)
        let networkService = DefaultNetworkService(config: MockNetworkConfig(), sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Received network error")

        Task {
            do {
                _ = try await networkService.requestTask(endpoint: EndpointMock<[String: String]>(path: "/success", method: .get)).value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .responseFailure(.notConnected):
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenErrorWithNotHttpResponse_thenCatchNotResponseError() {
        let config = MockNetworkConfig()
        let nonHTTPResponse = URLResponse(url: URL(string: "https://example.com")!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let emptyData = Data()

        let sessionManager = MockNetworkSessionManager(response: nonHTTPResponse, data: emptyData, error: nil)
        let networkService = DefaultNetworkService(config: config, sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Received not http response error")

        Task {
            do {
                _ = try await networkService.requestTask(endpoint: EndpointMock<[String: String]>(path: "/success", method: .get)).value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .responseFailure(.notHttpResponse):
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenErrorWithInvalidData_thenCatchInvalidDataError() {
        let config = MockNetworkConfig()
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock.apple.com/success")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let emptyData = Data()

        let sessionManager = MockNetworkSessionManager(response: mockResponse, data: emptyData, error: nil)
        let networkService = DefaultNetworkService(config: config, sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Received invalidData error")

        Task {
            do {
                _ = try await networkService.requestTask(endpoint: EndpointMock<[String: String]>(path: "/success", method: .get)).value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .responseFailure(.invalidData):
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenErrorWithCantDecodeData_thenCatchDecoderError() {
        let config = MockNetworkConfig()
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock.apple.com/success")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let invalidJsonData = "{\"id\": \"ABC\", \"name\": \"Test\"}".data(using: .utf8)!

        let sessionManager = MockNetworkSessionManager(response: mockResponse, data: invalidJsonData, error: nil)
        let networkService = DefaultNetworkService(config: config, sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Received decoder error")

        Task {
            do {
                let _: MockModel = try await networkService.requestTask(endpoint: EndpointMock(path: "/success", method: .get)).value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .responseFailure(.decodeError):
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenErrorWithURL_thenCatchURLError() {
        let config = MockNetworkConfig()
        let urlError = RequestGenerationError.invalidURL
        let sessionManager = MockNetworkSessionManager(response: nil, data: nil, error: urlError)
        let networkService = DefaultNetworkService(config: config, sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Request invalid URL error")

        Task {
            do {
                let _: MockModel = try await networkService.requestTask(endpoint: EndpointMock(path: "/success", method: .get)).value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .requestFailure(.invalidURL):
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenErrorWithWrongPath_thenCatchPathError() {
        let config = MockNetworkConfig()
        let urlError = RequestGenerationError.invalidPath
        let sessionManager = MockNetworkSessionManager(response: nil, data: nil, error: urlError)
        let networkService = DefaultNetworkService(config: config, sessionManager: sessionManager)

        let expectation = XCTestExpectation(description: "Request invalid URL error")

        Task {
            do {
                let _: MockModel = try await networkService.requestTask(endpoint: EndpointMock(path: "/success", method: .get)).value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .requestFailure(.invalidPath):
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func test_whenCallRequestComplete_thenInterceptorCalled() {
        let config = MockNetworkConfig()
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://mock.apple.com/success")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        let mockData = "{\"key\":\"value\"}".data(using: .utf8)!
        let sessionManager = MockNetworkSessionManager(response: mockResponse, data: mockData, error: nil)
        let networkService = DefaultNetworkService(config: config, sessionManager: sessionManager)

        let mockInterceptor = MockInterceptor()
        let expectation = XCTestExpectation(description: "Interceptor has called")

        Task {
            do {
                let _: [String: String] = try await networkService.requestTask(endpoint: EndpointMock(
                    path: "/success",
                    method: .get,
                    interceptors: [mockInterceptor]
                )).value
                XCTAssertTrue(mockInterceptor.processAfterGenerateRequestCalled)
                XCTAssertTrue(mockInterceptor.processBeforeDecodeCalled)
                XCTAssertTrue(mockInterceptor.processAfterDecodeCalled)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }
}
