import Combine
@testable import Currency
import XCTest

@MainActor
final class CurrencyConvertViewModelImpTests: XCTestCase {
    class MockCurrencyUseCase: CurrencyUseCase {
        var latestTimestamp: TimeInterval = 1_609_459_200 // 2021/01/01 09:00:00 JST

        var useCaseOutput: CurrencyUseCaseCallback?
        var initialCurrencyValue = Decimal(1.0)
        var currentCurrencyValue = Decimal(1.0)
        var currentCurrency = Currency.USD

        var selectedSymbols: [Currency] = [.USD, .JPY]
        var convertResults: [Currency: Decimal] = [.USD : Decimal(1), .JPY : Decimal(0)]

        var loadLatestCurrencyCalled = false
        var loadCurrcyCalled = false
        var convertCurrencyCalled = false
        var updateSelectedSymbolsCalled = false
        var lastConvertedCurrency: Currency?

        func updateSelectedSymbols(_ symbols: [Currency]) {
            selectedSymbols = symbols
            updateSelectedSymbolsCalled = true
        }

        func refreshCurrency() {
            loadLatestCurrencyCalled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.convertResults = [.USD: Decimal(1.0), .JPY: Decimal(0.9)]
                self.useCaseOutput?.didLoadSuccess(self.convertResults)
            }
        }

        func loadCurrency() {
            loadCurrcyCalled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.convertResults = [.USD: Decimal(1.0), .JPY: Decimal(0.9)]
                self.useCaseOutput?.didLoadSuccess(self.convertResults)
            }
        }

        func convertCurrency(from: Currency, value: Decimal) {
            convertCurrencyCalled = true
            lastConvertedCurrency = from
            currentCurrencyValue = value
            convertResults[from] = value
            useCaseOutput?.didUpdateConvertResults(convertResults)
        }

        func cancelRequestLatestCurrency() {}
    }

    enum RequestState {
        case initial
        case requesting
        case completed
    }
    var cancellables: Set<AnyCancellable> = []

    func testDidUpdateAmount_whenLoaded_thenGetCurrencyResultList() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        let amount = "100"
        mockUseCase.useCaseOutput = viewModel
        mockUseCase.convertResults = [.USD: Decimal(5), .JPY: Decimal(150)]

        viewModel.didUpdateAmount(amount)

        XCTAssertEqual(mockUseCase.currentCurrencyValue, Decimal(string: amount), "Use case should be called with updated amount")
        XCTAssertEqual(viewModel.itemViewModels.count, 2)
        XCTAssertEqual(viewModel.itemViewModels[0].title, Currency.USD.rawValue)
        XCTAssertEqual(viewModel.itemViewModels[0].valueString, "100")
        XCTAssertEqual(viewModel.itemViewModels[0].selected, true)
        XCTAssertEqual(viewModel.itemViewModels[1].selected, false)
    }

    func testDidTriggerRefresh_whenRefresh_thenRefreshCalled() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))

        viewModel.didTriggerRefresh()

        XCTAssertTrue(mockUseCase.loadLatestCurrencyCalled, "Load latest currency should be called")
    }

    func testDidSelectItem_whenChangeItem_thenSelectedIndexChanged() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        let newIndex = 1

        viewModel.didSelectItem(at: newIndex)

        XCTAssertEqual(viewModel.selectedIndex, newIndex, "Selected index should be updated")
        XCTAssertEqual(mockUseCase.currentCurrencyValue, mockUseCase.initialCurrencyValue, "Should call convertCurrency with initial value")
    }

    func testLastTimeString_whenRequestFinish_thenShowRequestSuccessTime() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))

        let expectedDateString = "2021-01-01 09:00:00"
        XCTAssertEqual(viewModel.lastTimeString, expectedDateString, "The lastTimeString should match the formatted date string")
    }

    func testDidInputValidValue_whenInputInvalid_thenTriggerViewModelUpdate() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        mockUseCase.useCaseOutput = viewModel
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])

        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, false)
        viewModel.didInputValidValue()
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])
        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, true)
    }

    func testDidResetInput_whenInputInvalid_thenTriggerViewModelUpdate() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        mockUseCase.useCaseOutput = viewModel
        viewModel.didInputValidValue()
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])

        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, true)
        viewModel.didResetInput()
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])
        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, false)
    }

    func testLoadingStatus_whenLoadCurrency_thenLoadingStatusChanged() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        mockUseCase.useCaseOutput = viewModel

        let firstStateChangeExpectation = XCTestExpectation(description: "First state change")
        let revertedStateChangeExpectation = XCTestExpectation(description: "Reverted state change")
        var requestState = RequestState.initial
        viewModel.isRequestingPublisher
            .sink { isRequesting in
                switch requestState {
                case .initial where isRequesting:
                    requestState = .requesting
                    firstStateChangeExpectation.fulfill()
                case .requesting where !isRequesting:
                    requestState = .completed
                    revertedStateChangeExpectation.fulfill()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        viewModel.viewDidLoad(viewController: UIViewController())

        wait(for: [firstStateChangeExpectation, revertedStateChangeExpectation], timeout: 3.0)
    }
    
    func testItemViewModelsPublisher_whenLoadCurrency_thenItemViewModelsGetCorrectReuslt() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        mockUseCase.useCaseOutput = viewModel
        let expectation = XCTestExpectation(description: "Publisher should emit updated item view models")
        var receivedInitialValue = false

        viewModel.itemViewModelsPublisher
            .sink { result in
                switch result {
                case .success(let itemViewModels):
                    if !receivedInitialValue {
                        XCTAssertEqual(itemViewModels.count, 2)
                        XCTAssertEqual(itemViewModels[0].title, Currency.USD.rawValue)
                        XCTAssertEqual(itemViewModels[0].valueString, "1")
                        XCTAssertEqual(itemViewModels[1].title, Currency.JPY.rawValue)
                        XCTAssertEqual(itemViewModels[1].valueString, "0")
                        receivedInitialValue = true
                    } else {
                        XCTAssertEqual(itemViewModels.count, 2)
                        XCTAssertEqual(itemViewModels[0].title, Currency.USD.rawValue)
                        XCTAssertEqual(itemViewModels[0].valueString, "1")
                        XCTAssertEqual(itemViewModels[1].title, Currency.JPY.rawValue)
                        XCTAssertEqual(itemViewModels[1].valueString, "0.9")
                        expectation.fulfill()
                    }
                case .failure(let error):
                    XCTFail("Unexpected error: \(error)")
                }
            }
            .store(in: &cancellables)

        viewModel.viewDidLoad(viewController: UIViewController())
        wait(for: [expectation], timeout: 3.0)
    }
}
