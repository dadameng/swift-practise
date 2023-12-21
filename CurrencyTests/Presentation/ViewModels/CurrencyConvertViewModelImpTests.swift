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
        var convertResults: [Currency: Decimal] = [:]

        var loadLatestCurrencyCalled = false
        var convertCurrencyCalled = false
        var updateSelectedSymbolsCalled = false
        var lastConvertedCurrency: Currency?

        func updateSelectedSymbols(_ symbols: [Currency]) {
            selectedSymbols = symbols
            updateSelectedSymbolsCalled = true
        }

        func loadLatestCurrency() {
            loadLatestCurrencyCalled = true
            DispatchQueue.global().async {
                self.convertResults = [.USD: Decimal(1.0), .EUR: Decimal(0.9)]
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

    func testDidUpdateAmount() {
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

    func testDidTriggerRefresh() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))

        viewModel.didTriggerRefresh()

        XCTAssertTrue(mockUseCase.loadLatestCurrencyCalled, "Load latest currency should be called")
    }

    func testDidSelectItem() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        let newIndex = 1

        viewModel.didSelectItem(at: newIndex)

        XCTAssertEqual(viewModel.selectedIndex, newIndex, "Selected index should be updated")
        XCTAssertEqual(mockUseCase.currentCurrencyValue, mockUseCase.initialCurrencyValue, "Should call convertCurrency with initial value")
    }

    func testLastTimeString() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))

        let expectedDateString = "2021-01-01 09:00:00"
        XCTAssertEqual(viewModel.lastTimeString, expectedDateString, "The lastTimeString should match the formatted date string")
    }

    func testDidInputValidValue() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        mockUseCase.useCaseOutput = viewModel
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])

        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, false)
        viewModel.didInputValidValue()
        // need trigger itemviewmodels update method
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])
        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, true)
    }

    func testDidResetInput() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        mockUseCase.useCaseOutput = viewModel
        viewModel.didInputValidValue()
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])

        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, true)
        viewModel.didResetInput()
        // need trigger itemviewmodels update method
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: Decimal(5), .JPY: Decimal(150)])
        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, false)
    }
}
