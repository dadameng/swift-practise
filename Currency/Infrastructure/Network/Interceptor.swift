import Foundation

enum InterceptorResult<T> {
    case continueProcessing
    case stopProcessing(T)
}

typealias RequestInterceptorResult<T> = (processedRequest: URLRequest, result: InterceptorResult<T>)
protocol RequestInterceptor {
    func processAfterGenerateRequest<T: ApiTask>(on sourceURLRequest: URLRequest, request: T)  -> RequestInterceptorResult<T.Response>
}

extension RequestInterceptor {
    func processAfterGenerateRequest<T: ApiTask>(on sourceURLRequest: URLRequest, request _: T)  -> RequestInterceptorResult<T.Response> {
        (sourceURLRequest, .continueProcessing)
    }
}

typealias ResponseInterceptorResult<T> = (processResponse: (Data, URLResponse), result: InterceptorResult<T>)
typealias DecodeResponseInterceptorResult<T> = (processedResponse: T, result: InterceptorResult<T>)

protocol ResponseInterceptor {
    func processBeforeDecode<T: ApiTask>(on rawResponse: (Data, URLResponse), request: T) -> ResponseInterceptorResult<T.Response>
    func processAfterDecode<T: ApiTask>(on decodedResponse: T.Response, request: T) -> DecodeResponseInterceptorResult<T.Response>
}

extension ResponseInterceptor {
    func processBeforeDecode<T>(on rawResponse: (Data, URLResponse), request _: T) -> ResponseInterceptorResult<T.Response> where T: ApiTask {
        (rawResponse, .continueProcessing)
    }

    func processAfterDecode<T: ApiTask>(on decodedResponse: T.Response, request _: T) -> DecodeResponseInterceptorResult<T.Response> {
        (decodedResponse, .continueProcessing)
    }
}

typealias NetworkInterceptor = RequestInterceptor & ResponseInterceptor

final class CacheInterceptor {
    let cache: APICache
    private var etagCache: [String: String] = [:]
    private var dateCache: [String: String] = [:]
    init(cache: APICache) {
        self.cache = cache
    }
}

extension CacheInterceptor: NetworkInterceptor {
    func processAfterGenerateRequest<T: ApiTask>(on sourceURLRequest: URLRequest, request: T) -> RequestInterceptorResult<T.Response> {
        let requestKey = request.uniqueKey

        // Retrieve ETag and Date from cache
        var newURLRequest = sourceURLRequest
        if let etag = etagCache[requestKey], let date = dateCache[requestKey] {
            newURLRequest.addValue(etag, forHTTPHeaderField: "If-None-Match")
            newURLRequest.addValue(date, forHTTPHeaderField: "If-Modified-Since")
        }
        
        return (newURLRequest, .continueProcessing)
    }
    
    func processBeforeDecode<T>(on rawResponse: (Data, URLResponse), request: T) -> ResponseInterceptorResult<T.Response> where T: ApiTask {
        guard let httpResponse = rawResponse.1 as? HTTPURLResponse, httpResponse.statusCode == 304 else {
            return (rawResponse, .continueProcessing)
        }
        let requestKey = request.uniqueKey

        if let cachedResponse: T.Response = cache.responseFromMemoryCache(key: requestKey) {
            return (rawResponse, .stopProcessing(cachedResponse))
        } else {
            if let etag = httpResponse.allHeaderFields["ETag"] as? String,
               let date = httpResponse.allHeaderFields["Date"] as? String {
                etagCache[requestKey] = etag
                dateCache[requestKey] = date
            }
            return (rawResponse, .continueProcessing)
        }
    }

    func processAfterDecode<T: ApiTask>(on decodedResponse: T.Response, request: T) -> DecodeResponseInterceptorResult<T.Response> {
        let requestKey = request.uniqueKey
        cache.convenienceStore(with: decodedResponse, key: requestKey)
        return (decodedResponse, .continueProcessing)
    }
}
