import Foundation

enum HTTPMethodType: String {
    case get = "GET"
    case head = "HEAD"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum BodyEncoding {
    case jsonSerializationData
    case stringEncodingAscii
}

enum RequestGenerationError: Error {
    case invalidURL
    case invalidPath
}

protocol Requestable {
    var path: String { get }
    var isFullPath: Bool { get }
    var method: HTTPMethodType { get }
    var headerParameters: [String: String] { get }
    var queryParametersEncodable: Encodable? { get }
    var queryParameters: [String: Any] { get }
    var bodyParametersEncodable: Encodable? { get }
    var bodyParameters: [String: Any] { get }
    var bodyEncoding: BodyEncoding { get }
    var throttleInterval: TimeInterval? { get }
    var requestInterceptors: [RequestInterceptor] { get }
    var uniqueKey: String { get }
    func urlRequest(with networkConfig: NetworkConfigurable) throws -> URLRequest
}

protocol Responseable {
    var responseDecoder: ResponseDecoder { get }
    var responseInterceptors: [ResponseInterceptor] { get }
}

protocol ApiTask: Requestable, Responseable {
    associatedtype Response: Codable
}

protocol ResponseDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

protocol ResponseEncoder {
    func encode<T: Encodable>(_ from: T) throws -> Data
}

// MARK: - Implementation

struct JSONResponseDecoder: ResponseDecoder {
    private let jsonDecoder = JSONDecoder()
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try jsonDecoder.decode(type, from: data)
    }
}

struct JSONResponseEncoder: ResponseEncoder {
    private let jsonEncoder = JSONEncoder()
    func encode(_ from: some Encodable) throws -> Data {
        try jsonEncoder.encode(from)
    }
}

extension Encodable {
    func encodedString() -> String? {
        guard let data = try? JSONEncoder().encode(self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}

extension Requestable {
    func url(with config: NetworkConfigurable) throws -> URL {
        let baseURL = config.baseURL.absoluteString.last != "/"
            ? config.baseURL.absoluteString + "/"
            : config.baseURL.absoluteString
        let endpoint = isFullPath ? path : baseURL.appending(path)

        guard var urlComponents = URLComponents(
            string: endpoint
        ), endpoint.isValidURL else { throw RequestGenerationError.invalidURL }
        var urlQueryItems = [URLQueryItem]()

        let queryParameters = try queryParametersEncodable?.toDictionary() ?? queryParameters
        queryParameters.forEach {
            urlQueryItems.append(URLQueryItem(name: $0.key, value: "\($0.value)"))
        }
        config.queryParameters.forEach {
            urlQueryItems.append(URLQueryItem(name: $0.key, value: $0.value))
        }
        urlComponents.queryItems = !urlQueryItems.isEmpty ? urlQueryItems : nil
        guard let url = urlComponents.url else { throw RequestGenerationError.invalidPath }
        return url
    }

    func urlRequest(with config: NetworkConfigurable) throws -> URLRequest {
        let url = try url(with: config)
        var urlRequest = URLRequest(url: url)
        var allHeaders: [String: String] = config.headers
        headerParameters.forEach { allHeaders.updateValue($1, forKey: $0) }

        let bodyParameters = try bodyParametersEncodable?.toDictionary() ?? bodyParameters
        if !bodyParameters.isEmpty {
            urlRequest.httpBody = encodeBody(bodyParameters: bodyParameters, bodyEncoding: bodyEncoding)
        }
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = allHeaders
        return urlRequest
    }

    private func encodeBody(bodyParameters: [String: Any], bodyEncoding: BodyEncoding) -> Data? {
        switch bodyEncoding {
        case .jsonSerializationData:
            try? JSONSerialization.data(withJSONObject: bodyParameters)
        case .stringEncodingAscii:
            bodyParameters.queryString.data(
                using: String.Encoding.ascii,
                allowLossyConversion: true
            )
        }
    }

    var requestInterceptors: [RequestInterceptor] {
        []
    }

    var uniqueKey: String {
        var components = [String]()

        components.append(path)
        components.append(method.rawValue)

        let sortedHeaderParams = headerParameters.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        components.append(sortedHeaderParams.joined(separator: "&"))

        if let encodableQuery = queryParametersEncodable?.encodedString() {
            components.append(encodableQuery)
        } else {
            let sortedQueryParams = queryParameters.map { "\($0.key)=\($0.value)" }.sorted()
            components.append(sortedQueryParams.joined(separator: "&"))
        }

        if let encodableBody = bodyParametersEncodable?.encodedString() {
            components.append(encodableBody)
        } else {
            let sortedBodyParams = bodyParameters.map { "\($0.key)=\($0.value)" }.sorted()
            components.append(sortedBodyParams.joined(separator: "&"))
        }

        return components.joined(separator: "|").md5
    }
}

extension Responseable {
    var responseInterceptors: [ResponseInterceptor] {
        []
    }

    var responseDecoder: ResponseDecoder {
        JSONResponseDecoder()
    }
}

struct APIEndpoint<T: Codable>: ApiTask {
    typealias Response = T

    let path: String
    let isFullPath: Bool
    let method: HTTPMethodType
    let headerParameters: [String: String]
    let queryParametersEncodable: Encodable?
    let queryParameters: [String: Any]
    let bodyParametersEncodable: Encodable?
    let bodyParameters: [String: Any]
    let bodyEncoding: BodyEncoding
    let responseDecoder: ResponseDecoder
    let endpointRequestInterceptors: [RequestInterceptor]
    let endpointResponseInterceptors: [ResponseInterceptor]
    var throttleInterval: TimeInterval?
    
    init(
        path: String,
        isFullPath: Bool = false,
        method: HTTPMethodType,
        headerParameters: [String: String] = [:],
        queryParametersEncodable: Encodable? = nil,
        queryParameters: [String: Any] = [:],
        bodyParametersEncodable: Encodable? = nil,
        bodyParameters: [String: Any] = [:],
        bodyEncoding: BodyEncoding = .jsonSerializationData,
        responseDecoder: ResponseDecoder = JSONResponseDecoder(),
        endpointRequestInterceptors: [RequestInterceptor] = [],
        endpointResponseInterceptors: [ResponseInterceptor] = [],
        throttleInterval : TimeInterval? = nil
    ) {
        self.path = path
        self.isFullPath = isFullPath
        self.method = method
        self.headerParameters = headerParameters
        self.queryParametersEncodable = queryParametersEncodable
        self.queryParameters = queryParameters
        self.bodyParametersEncodable = bodyParametersEncodable
        self.bodyParameters = bodyParameters
        self.bodyEncoding = bodyEncoding
        self.responseDecoder = responseDecoder
        self.endpointRequestInterceptors = endpointRequestInterceptors
        self.endpointResponseInterceptors = endpointResponseInterceptors
        self.throttleInterval = throttleInterval
    }
}

extension APIEndpoint: Requestable {
    var requestInterceptors: [RequestInterceptor] {
        endpointRequestInterceptors
    }
}

extension APIEndpoint: Responseable {
    var responseInterceptors: [ResponseInterceptor] {
        endpointResponseInterceptors
    }
}

private extension Dictionary {
    var queryString: String {
        map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? ""
    }
}

private extension Encodable {
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let jsonData = try JSONSerialization.jsonObject(with: data)
        return jsonData as? [String: Any]
    }
}

private extension String {
    var isValidURL: Bool {
        let detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        if let match = detector.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) {
            // it is a link, if the match covers the whole string
            return match.range.length == self.utf16.count
        } else {
            return false
        }
    }
}
