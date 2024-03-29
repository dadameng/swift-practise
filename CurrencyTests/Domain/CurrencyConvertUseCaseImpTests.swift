@testable import Currency
import XCTest

final class CurrencyConvertUseCaseImpTests: XCTestCase {
    class MockCurrencyRepository: CurrencyRepository {
        var fetchCurrencysLatestCalled = false
        var fetchCurrencysCalled = false
        var mockExchangeData: ExchangeData?
        var mockError: Error?

        func fetchCurrencys() -> FetchResult<ExchangeData> {
            fetchCurrencysCalled = true

            let task = Task<ExchangeData, Error> {
                if let data = mockExchangeData {
                    return data
                } else if let error = mockError {
                    throw error
                } else {
                    throw NetworkServiceError.responseFailure(.invalidData)
                }
            }

            return task
        }

        func fetchLatestCurrencys() -> FetchResult<ExchangeData> {
            fetchCurrencysLatestCalled = true
            let task = Task<ExchangeData, Error> {
                if let data = mockExchangeData {
                    return data
                } else if let error = mockError {
                    throw error
                } else {
                    throw NetworkServiceError.responseFailure(.invalidData)
                }
            }

            return task
        }
    }

    class MockUseCaseOutput: CurrencyUseCaseCallback {
        var updateSelectedSymbolsCalled = false
        var updateConvertResultsCalled = false
        var loadSuccessCalled = false
        var loadFailureCalled = false
        var mockConvertResults: [Currency: Decimal] = [:]
        var loadSuccessHandler: (() -> Void)?
        var loadFailureHandler: (() -> Void)?
        var didUpdateConvertResultsHandler: (() -> Void)?
        var loadFailureError: NetworkServiceError?

        func didUpdateSelectedSymbols(_: [Currency]) {
            updateSelectedSymbolsCalled = true
        }

        func didUpdateConvertResults(_ convertResults: [Currency: Decimal]) {
            updateConvertResultsCalled = true
            mockConvertResults = convertResults
            didUpdateConvertResultsHandler?()
        }

        func didLoadSuccess(_ convertResults: [Currency: Decimal]) {
            loadSuccessCalled = true
            mockConvertResults = convertResults

            loadSuccessHandler?()
        }

        func didLoadFailure(_ error: NetworkServiceError) {
            loadFailureCalled = true
            loadFailureError = error
            loadFailureHandler?()
        }
    }

    var useCase: CurrencyConvertUseCaseImp!
    var mockCurrencyRepository: MockCurrencyRepository!
    var mockUseCaseOutput: MockUseCaseOutput!

    override func setUp() {
        super.setUp()
        mockCurrencyRepository = MockCurrencyRepository()
        mockUseCaseOutput = MockUseCaseOutput()
        useCase = CurrencyConvertUseCaseImp(
            currencyRepository: mockCurrencyRepository,
            selectedSymbols: [.JPY, .USD],
            currentCurrency: .USD,
            initialCurrencyValue: Decimal(100)
        )
        useCase.useCaseOutputDelegate = mockUseCaseOutput
    }

    override func tearDown() {
        useCase = nil
        mockCurrencyRepository = nil
        mockUseCaseOutput = nil
        super.tearDown()
    }

    func testLoadLatestCurrency_whenRequestSuccess_thenCallbackSuccessBeingCalled() {
        var mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD")
        mockExchangeData.rates = [.JPY: 150, .USD: 1]
        mockCurrencyRepository.mockExchangeData = mockExchangeData

        let expectation = XCTestExpectation(description: "loadLatestCurrency completes")

        mockUseCaseOutput.loadSuccessHandler = {
            expectation.fulfill()
        }

        useCase.loadCurrency()

        wait(for: [expectation], timeout: 3.0)

        XCTAssertTrue(mockCurrencyRepository.fetchCurrencysCalled)
        XCTAssertFalse(mockCurrencyRepository.fetchCurrencysLatestCalled)
        XCTAssertTrue(mockUseCaseOutput.loadSuccessCalled)
        XCTAssertFalse(mockUseCaseOutput.loadFailureCalled)
        XCTAssertEqual(useCase.latestTimestamp, 123_123_123)
        XCTAssertEqual(useCase.convertResults[.JPY], Decimal(15000))
        XCTAssertEqual(mockUseCaseOutput.mockConvertResults.count, 2)
        XCTAssertEqual(mockUseCaseOutput.mockConvertResults[.JPY], Decimal(15000))
    }

    func testLoadLatestCurrency_whenRequestFail_thenCallbackFailBeingCalled() {
        let expectation = XCTestExpectation(description: "loadLatestCurrency completes")
        mockUseCaseOutput.loadFailureHandler = {
            expectation.fulfill()
        }
        useCase.loadCurrency()

        wait(for: [expectation], timeout: 3.0)

        XCTAssertTrue(mockCurrencyRepository.fetchCurrencysCalled)
        XCTAssertFalse(mockCurrencyRepository.fetchCurrencysLatestCalled)
        XCTAssertTrue(mockUseCaseOutput.loadFailureCalled)
        XCTAssertFalse(mockUseCaseOutput.loadSuccessCalled)
        XCTAssertEqual(useCase.convertResults, [.JPY: Decimal(0), .USD: Decimal(0)])
        XCTAssertEqual(mockUseCaseOutput.mockConvertResults.count, 0)
    }

    func testUpdateSelectedSymbols_whenCallUpdateSelectedSymbols_thenCallbackConvertBeingCalled() {
        var mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD")
        mockExchangeData.rates = [.JPY: 150, .USD: 1, .CNY: 7]
        mockCurrencyRepository.mockExchangeData = mockExchangeData
        var expectation = XCTestExpectation(description: "loadLatestCurrency completes")

        mockUseCaseOutput.loadSuccessHandler = {
            expectation.fulfill()
        }

        useCase.loadCurrency()

        wait(for: [expectation], timeout: 3.0)

        let newSymbols: [Currency] = [.USD, .CNY]
        expectation = XCTestExpectation(description: "Update selected symbols")

        mockUseCaseOutput.didUpdateConvertResultsHandler = {
            expectation.fulfill()
        }

        useCase.updateSelectedSymbols(newSymbols)
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockUseCaseOutput.mockConvertResults.keys.contains(.CNY))
        XCTAssertEqual(useCase.selectedSymbols, [.USD, .CNY])
        XCTAssertTrue(mockUseCaseOutput.updateConvertResultsCalled, "Callback for updated convert results should be called")
    }

    func testConvertCurrency_whenLoadCurrency_thenConvertNewCurrency() {
        var mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD")
        mockExchangeData.rates = [.JPY: 150, .USD: 1]
        mockCurrencyRepository.mockExchangeData = mockExchangeData
        let expectation = XCTestExpectation(description: "loadLatestCurrency completes")

        mockUseCaseOutput.loadSuccessHandler = {
            expectation.fulfill()
        }

        useCase.loadCurrency()

        wait(for: [expectation], timeout: 3.0)

        let currency: Currency = .JPY
        let value = Decimal(150)

        useCase.convertCurrency(from: currency, value: value)

        XCTAssertTrue(mockUseCaseOutput.updateConvertResultsCalled)
        XCTAssertEqual(mockUseCaseOutput.mockConvertResults[.USD], Decimal(1))
    }

    func testCancelLoad_whenLoadCurrency_thenCancel() {
        let expectation = XCTestExpectation(description: "loadLatestCurrency completes")

        mockUseCaseOutput.loadFailureHandler = {
            expectation.fulfill()
        }

        useCase.loadCurrency()
        useCase.cancelRequestLatestCurrency()

        wait(for: [expectation], timeout: 3.0)

        XCTAssertTrue(mockUseCaseOutput.loadFailureCalled)
        XCTAssertFalse(mockUseCaseOutput.loadSuccessCalled)
        XCTAssertEqual(mockUseCaseOutput.loadFailureError?.localizedDescription, NetworkServiceError.responseFailure(.cancelled).localizedDescription)
    }

    func testRefreshLoad_whenRefresh_thenLatestBellCalled() {
        var mockExchangeData = ExchangeData(disclaimer: "", license: "", timestamp: 123_123_123, base: "USD")
        mockExchangeData.rates = [.JPY: 150, .USD: 1]
        mockCurrencyRepository.mockExchangeData = mockExchangeData

        let expectation = XCTestExpectation(description: "loadLatestCurrency completes")

        mockUseCaseOutput.loadSuccessHandler = {
            expectation.fulfill()
        }

        useCase.refreshCurrency()

        wait(for: [expectation], timeout: 3.0)

        XCTAssertTrue(mockCurrencyRepository.fetchCurrencysLatestCalled)
        XCTAssertFalse(mockCurrencyRepository.fetchCurrencysCalled)
        XCTAssertTrue(mockUseCaseOutput.loadSuccessCalled)
        XCTAssertFalse(mockUseCaseOutput.loadFailureCalled)
    }
}
