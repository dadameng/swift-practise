import Foundation

protocol NetworkConfigurable {
    var baseURL: URL { get }
    var headers: [String: String] { get }
    var queryParameters: [String: String] { get }
    var commonRequestInterceptors: [RequestInterceptor] { get }
    var commonResponseInterceptors: [ResponseInterceptor] { get }
}

extension NetworkConfigurable {
    var commonRequestInterceptors: [RequestInterceptor] {
        []
    }

    var commonResponseInterceptors: [ResponseInterceptor] {
        []
    }
}

struct ApiDataNetworkConfig: NetworkConfigurable {
    let baseURL: URL
    let headers: [String: String]
    let queryParameters: [String: String]

    init(
        baseURL: URL,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.queryParameters = queryParameters
    }
}
