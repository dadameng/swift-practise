import Foundation

enum InterceptorResult<T> {
    case continueProcessing
    case stopProcessing(T)
}

typealias RequestInterceptorResult<T> = (processedRequest: URLRequest, result: InterceptorResult<T>)
protocol RequestInterceptor {
    func processAfterGenerateRequest<T: ApiTask>(on sourceURLRequest: URLRequest, request: T) async -> RequestInterceptorResult<T.Response>
}

extension RequestInterceptor {
    func processAfterGenerateRequest<T: ApiTask>(on sourceURLRequest: URLRequest, request _: T) async -> RequestInterceptorResult<T.Response> {
        (sourceURLRequest, .continueProcessing)
    }
}

typealias ResponseInterceptorResult = (processResponse: (Data, URLResponse), continueProcessing: Bool)

protocol ResponseInterceptor {
    func processBeforeDecode<T: ApiTask>(on rawResponse: (Data, URLResponse), request: T) -> ResponseInterceptorResult
    func processAfterDecode<T: ApiTask>(on decodedResponse: T.Response, request: T) -> (processedResponse: T.Response, continueProcessing: Bool)
}

extension ResponseInterceptor {
    func processBeforeDecode(on rawResponse: (Data, URLResponse), request _: some ApiTask) -> ResponseInterceptorResult {
        (rawResponse, true)
    }

    func processAfterDecode<T: ApiTask>(on decodedResponse: T.Response, request _: T) -> (processedResponse: T.Response, continueProcessing: Bool) {
        (decodedResponse, true)
    }
}

typealias NetworkInterceptor = RequestInterceptor & ResponseInterceptor

private protocol ApiTaskThrottle: Requestable {
    var throttleInterval: TimeInterval { get }
}

extension APIEndpoint: ApiTaskThrottle {
    var throttleInterval: TimeInterval {
        30 * 60
    }
}

final class ThrottleInterceptor {
    let cache: APICache
    @UserDefault(key: "requestTimeMap", defaultValue: [:]) var requestTimeMap: [String: TimeInterval]

    init(cache: APICache) {
        self.cache = cache
    }
}

extension ThrottleInterceptor: NetworkInterceptor {
    func processAfterGenerateRequest<T: ApiTask>(on sourceURLRequest: URLRequest, request: T) async -> RequestInterceptorResult<T.Response> {
        guard let throttleRequest = request as? (any ApiTaskThrottle) else {
            return (sourceURLRequest, .continueProcessing)
        }

        let now = Date().timeIntervalSince1970
        let requestKey = throttleRequest.uniqueKey

        if let lastRequestTime = requestTimeMap[requestKey], now - lastRequestTime < throttleRequest.throttleInterval {
            do {
                if let cacheResponse: T.Response = try await cache.convenienceResponse(key: requestKey) {
                    return (sourceURLRequest, .stopProcessing(cacheResponse))
                }
            } catch {
                print("Read cache error: \(error)")
            }

            requestTimeMap.removeValue(forKey: requestKey)
        }

        return (sourceURLRequest, .continueProcessing)
    }

    func processAfterDecode<T: ApiTask>(on decodedResponse: T.Response, request: T) -> (processedResponse: T.Response, continueProcessing: Bool) {
        let requestKey = request.uniqueKey
        requestTimeMap[requestKey] = Date().timeIntervalSince1970
        cache.convenienceStore(with: decodedResponse, key: requestKey)

        return (decodedResponse, true)
    }
}
