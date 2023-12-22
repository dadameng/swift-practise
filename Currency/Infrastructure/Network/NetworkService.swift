import Foundation

enum ResponseError: Error {
    case notConnected
    case cancelled
    case error(statusCode: Int, data: Data?)
    case decodeError(originalError: DecodingError)
    case notHttpResponse
    case invalidData
}

enum NetworkServiceError: Error {
    case requestFailure(RequestGenerationError)
    case responseFailure(ResponseError)
    case generic(Error)
}

protocol NetworkService {
    func requestTask<T: ApiTask>(endpoint: T) -> FetchResult<T.Response>
}

protocol NetworkSessionManager {
    func request(_ request: URLRequest) async throws -> (Data, URLResponse)
}

typealias FetchResult<T> = Task<T, Error>

// MARK: - Implementation

final class DefaultNetworkSessionManager: NetworkSessionManager {
    func request(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

struct DefaultNetworkService {
    private let config: NetworkConfigurable
    private let sessionManager: NetworkSessionManager

    init(
        config: NetworkConfigurable,
        sessionManager: NetworkSessionManager = DefaultNetworkSessionManager()
    ) {
        self.config = config
        self.sessionManager = sessionManager
    }
}

extension DefaultNetworkService: NetworkService {
    func requestTask<T: ApiTask>(endpoint: T) -> FetchResult<T.Response> {
        Task<T.Response, Error> { () -> T.Response in
            do {
                if Task.isCancelled {
                    throw NetworkServiceError.responseFailure(.cancelled)
                }

                var request = try endpoint.urlRequest(with: config)

                let requestInterceptors = config.commonRequestInterceptors + endpoint.requestInterceptors

                for interceptor in requestInterceptors {
                    let (processedRequest, result) = interceptor.processAfterGenerateRequest(on: request, request: endpoint)
                    request = processedRequest
                    if case let .stopProcessing(decodedResponse) = result {
                        return decodedResponse
                    }
                }

                let (data, response) = try await sessionManager.request(request)
                if Task.isCancelled {
                    throw NetworkServiceError.responseFailure(.cancelled)
                }
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkServiceError.responseFailure(.notHttpResponse)
                }
                
                guard !data.isEmpty else {
                    throw NetworkServiceError.responseFailure(.invalidData)
                }

                let responseInterceptors = config.commonResponseInterceptors + endpoint.responseInterceptors
                var currentResponse = (data, response)
                for interceptor in responseInterceptors {
                    let (processResponse, result) = interceptor.processBeforeDecode(on: currentResponse, request: endpoint)
                    currentResponse = processResponse
                    if case let .stopProcessing(decodedResponse) = result {
                        return decodedResponse
                    }
                }

                guard (200 ... 299).contains(httpResponse.statusCode) else {
                    throw NetworkServiceError.responseFailure(.error(statusCode: httpResponse.statusCode, data: data))
                }

                var decodedResponse = try endpoint.responseDecoder.decode(T.Response.self, from: currentResponse.0)

                for interceptor in responseInterceptors {
                    let (processedResponse, result) = interceptor.processAfterDecode(on: decodedResponse, request: endpoint)
                    decodedResponse = processedResponse
                    if case let .stopProcessing(resultValue) = result {
                        return resultValue
                    }
                }
                return decodedResponse
            } catch let urlError as URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    throw NetworkServiceError.responseFailure(.notConnected)
                case .cancelled:
                    throw NetworkServiceError.responseFailure(.cancelled)
                default:
                    throw NetworkServiceError.generic(urlError)
                }
            } catch let wrappedError as NetworkServiceError {
                throw wrappedError
            } catch let requestError as RequestGenerationError {
                throw NetworkServiceError.requestFailure(requestError)
            } catch _ as CancellationError {
                throw NetworkServiceError.responseFailure(.cancelled)
            } catch let decodingError as DecodingError {
                throw NetworkServiceError.responseFailure(.decodeError(originalError: decodingError))
            } catch {
                print("error \(error)")
                throw NetworkServiceError.generic(error)
            }
        }
    }
}
