import Foundation

final class CurrencyRepositoryImp {
    struct Dependencies {
        let networkService: NetworkService
        let apiCache: APICache
        let endpointsFactory: CurrencyModuleEndpointsFactory
    }

    @UserDefault(key: "requestTimeMap", defaultValue: [:]) private var requestTimeMap: [String: TimeInterval]
    private let dependencies: Dependencies
    init(dependencies: Dependencies, userDefaults: UserDefaults = .standard) {
        self.dependencies = dependencies
        _requestTimeMap.storage = userDefaults
    }
}

extension CurrencyRepositoryImp: CurrencyRepository {
    func fetchLatestCurrencys() -> FetchResult<ExchangeData> {
        let endpoint = dependencies.endpointsFactory.currencyLatest()
        let requestKey = endpoint.uniqueKey
        requestTimeMap[requestKey] = Date().timeIntervalSince1970
        return dependencies.networkService.requestTask(endpoint: endpoint)
    }

    func fetchCurrencys() -> FetchResult<ExchangeData> {
        let endpoint = dependencies.endpointsFactory.currencyLatest()
        let now = Date().timeIntervalSince1970
        let requestKey = endpoint.uniqueKey

        return Task {
            // Attempt to fetch data from the cache, if the last request time for the given requestKey is within the throttle interval
            if let throttleInterval = endpoint.throttleInterval, let lastRequestTime = requestTimeMap[requestKey],
               now - lastRequestTime < throttleInterval
            {
                do {
                    if let cacheResponse: ExchangeData = try await dependencies.apiCache.convenienceResponse(key: requestKey) {
                        return cacheResponse
                    }
                } catch {
                    print("Read cache error: \(error)")
                }
            }

            do {
                // Attempt the primary data fetching operation
                requestTimeMap[requestKey] = Date().timeIntervalSince1970
                return try await fetchLatestCurrencys().value
            } catch {
                // Try to retrieve data from the cache, and if it fails, rethrow the original error
                guard let cacheResponse: ExchangeData = try? await dependencies.apiCache.convenienceResponse(key: requestKey) else {
                    throw error
                }
                return cacheResponse
            }
        }
    }
}
