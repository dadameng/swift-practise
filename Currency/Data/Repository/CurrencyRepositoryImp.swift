import Foundation

final class CurrencyRepositoryImp {
    struct Dependencies {
        let networkService: NetworkService
        let networkInterceptor: [NetworkInterceptor]
        let apiCache: APICache
    }

    @UserDefault(key: "requestTimeMap", defaultValue: [:]) private var requestTimeMap: [String: TimeInterval]

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

private protocol ApiTaskThrottle: Requestable {
    var throttleInterval: TimeInterval { get }
}

extension APIEndpoint: ApiTaskThrottle {
    var throttleInterval: TimeInterval {
        30 * 60
    }
}

extension CurrencyRepositoryImp: CurrencyRepository {
    func fetchLatestCurrencys() -> FetchResult<ExchangeData> {
        let endpoint = APIEndpoints.currencyLatest(interceptor: dependencies.networkInterceptor)
        return dependencies.networkService.requestTask(endpoint: endpoint)
    }

    func fetchCurrencys() -> FetchResult<ExchangeData> {
        let endpoint = APIEndpoints.currencyLatest(interceptor: dependencies.networkInterceptor)

        let now = Date().timeIntervalSince1970
        let requestKey = endpoint.uniqueKey

        return Task {
            if let lastRequestTime = requestTimeMap[requestKey],
               now - lastRequestTime < endpoint.throttleInterval {
                do {
                    if let cacheResponse: ExchangeData = try await dependencies.apiCache.convenienceResponse(key: requestKey) {
                        return cacheResponse
                    }
                } catch {
                    print("Read cache error: \(error)")
                }
            }
            requestTimeMap[requestKey] = Date().timeIntervalSince1970
            return try await fetchLatestCurrencys().value
        }
    }
}
