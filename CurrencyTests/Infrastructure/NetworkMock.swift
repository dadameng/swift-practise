@testable import Currency
import Foundation

struct MockNetworkConfig: NetworkConfigurable {
    let baseURL: URL = .init(string: "https://mock.apple.com")!
    let headers: [String: String] = [:]
    let queryParameters: [String: String] = [:]
}

struct MockModel: Codable {
    var id: Int
    var name: String
}

final class MockInterceptor: NetworkInterceptor {
    var processAfterGenerateRequestCalled = false
    var processBeforeDecodeCalled = false
    var processAfterDecodeCalled = false

    func processAfterGenerateRequest<T: ApiTask>(on sourceURLRequest: URLRequest, request _: T) -> RequestInterceptorResult<T.Response> {
        processAfterGenerateRequestCalled = true
        return (sourceURLRequest, .continueProcessing)
    }

    func processBeforeDecode<T>(on rawResponse: (Data, URLResponse), request _: T) -> ResponseInterceptorResult<T.Response> where T: ApiTask {
        processBeforeDecodeCalled = true
        return (rawResponse, .continueProcessing)
    }

    func processAfterDecode<T: ApiTask>(on decodedResponse: T.Response, request _: T) -> DecodeResponseInterceptorResult<T.Response> {
        processAfterDecodeCalled = true
        return (decodedResponse, .continueProcessing)
    }
}

struct MockNetworkSessionManager: NetworkSessionManager {
    let response: URLResponse?
    let data: Data?
    let error: Error?
    let genericError = NSError(
        domain: "com.apple.mock.error",
        code: 1001,
        userInfo: [NSLocalizedDescriptionKey: "should have error or data & response"]
    )

    func request(_: URLRequest) async throws -> (Data, URLResponse) {
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        if let error = error {
            throw error
        }

        if let data = data, let response = response {
            return (data, response)
        } else {
            throw genericError
        }
    }
}

final class EndpointMock<T: Codable>: ApiTask {
    typealias Response = T
    var path: String
    var isFullPath: Bool = false
    var method: HTTPMethodType
    var headerParameters: [String: String] = [:]
    var queryParametersEncodable: Encodable?
    var queryParameters: [String: Any] = [:]
    var bodyParametersEncodable: Encodable?
    var bodyParameters: [String: Any] = [:]
    var bodyEncoding: BodyEncoding = .jsonSerializationData
    var interceptors: [NetworkInterceptor] = []
    var throttleInterval: TimeInterval? = 2

    init(path: String, method: HTTPMethodType, interceptors: [NetworkInterceptor] = []) {
        self.path = path
        self.method = method
        self.interceptors = interceptors
    }

    var uniqueKey: String {
        return "\(path)|\(method.rawValue)"
    }

    var requestInterceptors: [RequestInterceptor] {
        interceptors
    }

    var responseInterceptors: [ResponseInterceptor] {
        interceptors
    }

    var responseDecoder: ResponseDecoder {
        JSONResponseDecoder()
    }

    func urlRequest(with _: NetworkConfigurable) throws -> URLRequest {
        // Use the provided extension method to create a URLRequest
        URLRequest(url: URL(string: "\(path)")!)
    }
}
