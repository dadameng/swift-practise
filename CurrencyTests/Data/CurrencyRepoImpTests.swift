@testable import Currency
import XCTest

final class CurrencyRepoImpTests: XCTestCase {
    struct MockNetworkService: NetworkService {
        var mockResponse: Any?
        var mockError: Error?
        var hasBeenCalled : Bool = false
        
        func requestTask<T>(endpoint _: T) -> FetchResult<T.Response> where T: ApiTask {
            return Task<T.Response, Error> {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                if let error = mockError {
                    throw error
                } else if let response = mockResponse as? T.Response {
                    return response
                } else {
                    throw URLError(.badServerResponse)
                }
            }
        }
    }
    
    struct MockCurrencyModuleEndpointsFactory: CurrencyModuleEndpointsFactory {
        
        let throttleInterval : TimeInterval
        
        init(throttleInterval: TimeInterval) {
            self.throttleInterval = throttleInterval
        }
        
        func currencyLatest() -> APIEndpoint<ExchangeData> {
            APIEndpoint<ExchangeData>(
                path: "latest.json",
                method: .get,
                queryParameters: ["base": "USD"],
                throttleInterval: throttleInterval
            )
        }
    }

    final class MockAPICache: APICache {
        var maxCacheDuration: TimeInterval = 60 * 60
        var maxMemoryCost: Int = 10_000_000
        var maxCacheSize: Int = 1024 * 1024

        var memoryCacheHasRetrieved = false
        var diskCacheHasRetrieved = false

        private var memoryCache: [String: Codable] = [:]
        private var diskCache: [String: Codable] = [:]

        init(memoryCache: [String: Codable], diskCache: [String: Codable]) {
            self.memoryCache = memoryCache
            self.diskCache = diskCache
        }

        func convenienceStore<T: Codable>(with response: T, key: String) {
            memoryCache[key] = response
            diskCache[key] = response
        }

        func storeMemoryCache<T: Codable>(with response: T, key: String) {
            memoryCache[key] = response
        }

        func storeResponseToDisk<T: Codable>(with response: T, key: String) {
            diskCache[key] = response
        }

        func convenienceResponse<T: Codable>(key: String) async throws -> T? {
            memoryCacheHasRetrieved = true
            diskCacheHasRetrieved = true
            return memoryCache[key] as? T
        }

        func responseFromMemoryCache<T: Codable>(key: String) -> T? {
            memoryCacheHasRetrieved = true
            return memoryCache[key] as? T
        }

        func responseFromDiskCache<T: Codable>(key: String) async throws -> T? {
            diskCacheHasRetrieved = true
            return diskCache[key] as? T
        }

        func removeMemoryCache(key: String) {
            memoryCache.removeValue(forKey: key)
        }

        func removeDiskCache(key: String) {
            diskCache.removeValue(forKey: key)
        }

        func cleanMemoryCache() {
            memoryCache.removeAll()
        }

        func cleanDishCache() {
            diskCache.removeAll()
        }
    }

    func testRequestRefresh_whenRefresh_thenServiceCalled() {
        let mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD", rates: DictionaryWrapper(wrappedValue: [Currency.JPY: 150, Currency.USD: 1]))
        let mockNetworkService = MockNetworkService(mockResponse: mockExchangeData)
        let mockAPICache = MockAPICache(memoryCache: [:], diskCache: [:])
        let endpointsFactory = MockCurrencyModuleEndpointsFactory(throttleInterval: 3)
        let currencyRepoImp = CurrencyRepositoryImp(dependencies: .init(
            networkService: mockNetworkService,
            apiCache: mockAPICache,
            endpointsFactory: endpointsFactory
        ))

        let expectation = XCTestExpectation(description: "Refresh data")
        
        Task {
            do {
                let result = try await currencyRepoImp.fetchLatestCurrencies().value
                XCTAssertEqual(result.rates[.JPY], mockExchangeData.rates[.JPY])
                XCTAssertEqual(result.rates[.USD], mockExchangeData.rates[.USD])
                XCTAssertFalse(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertFalse(mockAPICache.diskCacheHasRetrieved)
                expectation.fulfill()

            } catch {
                XCTFail("Received fetchLatestCurrencies \(error)")
            }
        }
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testloadCurrency_whenLoadWithinThrottle_thenFetchFromCache() {
        let mockCurrency = [Currency.JPY: Decimal(150), Currency.USD: Decimal(100)]
        let mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD", rates:DictionaryWrapper(wrappedValue: mockCurrency))
        let endpointsFactory = MockCurrencyModuleEndpointsFactory(throttleInterval: 100000)
        let mockEndpoint = endpointsFactory.currencyLatest()
        let mockRequestKey = mockEndpoint.uniqueKey
        let mockNetworkService = MockNetworkService(mockError: NetworkServiceError.responseFailure(.invalidData))
        let mockAPICache = MockAPICache(memoryCache: [mockRequestKey: mockExchangeData], diskCache: [mockRequestKey: mockExchangeData])
        guard let userDefaults = UserDefaults(suiteName: "TestDefaults") else {
             XCTFail("Failed to create UserDefaults for testing")
             return
         }
        let currencyRepoImp = CurrencyRepositoryImp(dependencies: .init(
            networkService: mockNetworkService,
            apiCache: mockAPICache,
            endpointsFactory: endpointsFactory
        ), userDefaults: userDefaults)

        userDefaults.set([ mockRequestKey: Date().timeIntervalSince1970 ], forKey: "requestTimeMap")
        let expectation = XCTestExpectation(description: "Load data")
        
        Task {
            do {
                let result = try await currencyRepoImp.fetchCurrencies().value
                XCTAssertEqual(result.rates[.JPY], mockExchangeData.rates[.JPY])
                XCTAssertEqual(result.rates[.USD], mockExchangeData.rates[.USD])
                XCTAssertTrue(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertTrue(mockAPICache.diskCacheHasRetrieved)
                expectation.fulfill()

            } catch {
                XCTFail("Received fetchLatestCurrencies \(error)")
            }
        }
        wait(for: [expectation], timeout: 3.0)
        userDefaults.removePersistentDomain(forName: "TestDefaults")
    }
    
    func testloadCurrency_whenLoadMoreThanThrottle_thenFetchFromRemote() {
        let mockCurrency = [Currency.JPY: Decimal(150), Currency.USD: Decimal(100)]
        let mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD", rates:DictionaryWrapper(wrappedValue: mockCurrency))
        let endpointsFactory = MockCurrencyModuleEndpointsFactory(throttleInterval: 0)
        let mockEndpoint = endpointsFactory.currencyLatest()
        let mockRequestKey = mockEndpoint.uniqueKey
        let mockNetworkService = MockNetworkService(mockResponse: mockExchangeData)
        let mockAPICache = MockAPICache(memoryCache: [mockRequestKey: mockExchangeData], diskCache: [mockRequestKey: mockExchangeData])
        guard let userDefaults = UserDefaults(suiteName: "TestDefaults") else {
             XCTFail("Failed to create UserDefaults for testing")
             return
         }
        let currencyRepoImp = CurrencyRepositoryImp(dependencies: .init(
            networkService: mockNetworkService,
            apiCache: mockAPICache,
            endpointsFactory: endpointsFactory
        ), userDefaults: userDefaults)

        userDefaults.set([ mockRequestKey: Date().timeIntervalSince1970 ], forKey: "requestTimeMap")
        let expectation = XCTestExpectation(description: "Load data")
        
        Task {
            do {
                let result = try await currencyRepoImp.fetchCurrencies().value
                XCTAssertEqual(result.rates[.JPY], mockExchangeData.rates[.JPY])
                XCTAssertEqual(result.rates[.USD], mockExchangeData.rates[.USD])
                XCTAssertFalse(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertFalse(mockAPICache.diskCacheHasRetrieved)
                expectation.fulfill()

            } catch {
                XCTFail("Received fetchLatestCurrencies \(error)")
            }
        }
        wait(for: [expectation], timeout: 3.0)
        userDefaults.removePersistentDomain(forName: "TestDefaults")
    }
    
    func testloadCurrency_whenLoadWithinThrottleButNoCache_thenFetchFromRemote() {
        let mockCurrency = [Currency.JPY: Decimal(150), Currency.USD: Decimal(100)]
        let mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD", rates:DictionaryWrapper(wrappedValue: mockCurrency))
        let endpointsFactory = MockCurrencyModuleEndpointsFactory(throttleInterval: 1000)
        let mockEndpoint = endpointsFactory.currencyLatest()
        let mockRequestKey = mockEndpoint.uniqueKey
        let mockNetworkService = MockNetworkService(mockResponse: mockExchangeData)
        let mockAPICache = MockAPICache(memoryCache: [:], diskCache: [: ])
        guard let userDefaults = UserDefaults(suiteName: "TestDefaults") else {
             XCTFail("Failed to create UserDefaults for testing")
             return
         }
        let currencyRepoImp = CurrencyRepositoryImp(dependencies: .init(
            networkService: mockNetworkService,
            apiCache: mockAPICache,
            endpointsFactory: endpointsFactory
        ), userDefaults: userDefaults)

        userDefaults.set([ mockRequestKey: Date().timeIntervalSince1970 ], forKey: "requestTimeMap")
        let expectation = XCTestExpectation(description: "Load data")
        
        Task {
            do {
                XCTAssertFalse(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertFalse(mockAPICache.diskCacheHasRetrieved)
                let result = try await currencyRepoImp.fetchCurrencies().value
                XCTAssertEqual(result.rates[.JPY], mockExchangeData.rates[.JPY])
                XCTAssertEqual(result.rates[.USD], mockExchangeData.rates[.USD])
                XCTAssertTrue(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertTrue(mockAPICache.diskCacheHasRetrieved)
                expectation.fulfill()

            } catch {
                XCTFail("Received fetchLatestCurrencies \(error)")
            }
        }
        wait(for: [expectation], timeout: 3.0)
        userDefaults.removePersistentDomain(forName: "TestDefaults")
    }
    
    func testloadCurrency_whenLoadMoreThrottleButRequestError_thenFetchCache() {
        let mockCurrency = [Currency.JPY: Decimal(150), Currency.USD: Decimal(100)]
        let mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD", rates:DictionaryWrapper(wrappedValue: mockCurrency))
        let endpointsFactory = MockCurrencyModuleEndpointsFactory(throttleInterval: 0)
        let mockEndpoint = endpointsFactory.currencyLatest()
        let mockRequestKey = mockEndpoint.uniqueKey
        let mockNetworkService = MockNetworkService(mockError: NetworkServiceError.responseFailure(.invalidData))
        let mockAPICache = MockAPICache(memoryCache: [mockRequestKey: mockExchangeData], diskCache: [mockRequestKey: mockExchangeData])
        guard let userDefaults = UserDefaults(suiteName: "TestDefaults") else {
             XCTFail("Failed to create UserDefaults for testing")
             return
         }
        let currencyRepoImp = CurrencyRepositoryImp(dependencies: .init(
            networkService: mockNetworkService,
            apiCache: mockAPICache,
            endpointsFactory: endpointsFactory
        ), userDefaults: userDefaults)

        userDefaults.set([ mockRequestKey: Date().timeIntervalSince1970 ], forKey: "requestTimeMap")
        let expectation = XCTestExpectation(description: "Load data")
        
        Task {
            do {
                XCTAssertFalse(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertFalse(mockAPICache.diskCacheHasRetrieved)
                let result = try await currencyRepoImp.fetchCurrencies().value
                XCTAssertEqual(result.rates[.JPY], mockExchangeData.rates[.JPY])
                XCTAssertEqual(result.rates[.USD], mockExchangeData.rates[.USD])
                XCTAssertTrue(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertTrue(mockAPICache.diskCacheHasRetrieved)
                expectation.fulfill()

            } catch {
                XCTFail("Received fetchLatestCurrencies \(error)")
            }
        }
        wait(for: [expectation], timeout: 3.0)
        userDefaults.removePersistentDomain(forName: "TestDefaults")
    }
    
    func testloadCurrency_whenLoadMoreThrottleButRequestErrorAndNoCache_thenThrowError() {
        let endpointsFactory = MockCurrencyModuleEndpointsFactory(throttleInterval: 0)
        let mockEndpoint = endpointsFactory.currencyLatest()
        let mockRequestKey = mockEndpoint.uniqueKey
        let mockNetworkService = MockNetworkService(mockError: NetworkServiceError.responseFailure(.invalidData))
        let mockAPICache = MockAPICache(memoryCache: [: ], diskCache: [: ])
        guard let userDefaults = UserDefaults(suiteName: "TestDefaults") else {
             XCTFail("Failed to create UserDefaults for testing")
             return
         }
        let currencyRepoImp = CurrencyRepositoryImp(dependencies: .init(
            networkService: mockNetworkService,
            apiCache: mockAPICache,
            endpointsFactory: endpointsFactory
        ), userDefaults: userDefaults)

        userDefaults.set([ mockRequestKey: Date().timeIntervalSince1970 ], forKey: "requestTimeMap")
        let expectation = XCTestExpectation(description: "Load data")
        
        Task {
            do {
                XCTAssertFalse(mockAPICache.memoryCacheHasRetrieved)
                XCTAssertFalse(mockAPICache.diskCacheHasRetrieved)
                _ = try await currencyRepoImp.fetchCurrencies().value
            } catch let requestError as NetworkServiceError {
                switch requestError {
                case .responseFailure(.invalidData):
                    XCTAssertTrue(mockAPICache.memoryCacheHasRetrieved)
                    XCTAssertTrue(mockAPICache.diskCacheHasRetrieved)
                    expectation.fulfill()
                default:
                    XCTFail("Expected .cancelled error, received \(requestError)")
                }
            }
        }
        wait(for: [expectation], timeout: 3.0)
        userDefaults.removePersistentDomain(forName: "TestDefaults")
    }
}
