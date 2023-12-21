@testable import Currency
import XCTest

@MainActor
final class CurrencyConvertViewModelImpTests: XCTestCase {
    class MockCurrencyUseCase: CurrencyUseCase {
        var latestTimestamp: TimeInterval = 1_609_459_200 // 2021/01/01 09:00:00 JST

        var useCaseOutput: CurrencyUseCaseCallback?
        var initialCurrencyValue: String = "1.0"
        var selectedSymbols: [Currency] = [.USD, .JPY]
        var convertResults: [Currency: String] = [:]

        var loadLatestCurrencyCalled = false
        var convertCurrencyCalled = false
        var updateSelectedSymbolsCalled = false
        var lastConvertedCurrency: Currency?
        var lastConvertedAmount: String?

        func updateSelectedSymbols(_ symbols: [Currency]) {
            selectedSymbols = symbols
            updateSelectedSymbolsCalled = true
        }

        func loadLatestCurrency() {
            loadLatestCurrencyCalled = true
            DispatchQueue.global().async {
                self.convertResults = [.USD: "1.0", .EUR: "0.9"]
                self.useCaseOutput?.didLoadSuccess(self.convertResults)
            }
        }

        func convertCurrency(from: Currency, value: String) {
            convertCurrencyCalled = true
            lastConvertedCurrency = from
            lastConvertedAmount = value
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
        mockUseCase.convertResults = [.USD: "5", .JPY: "150"]

        viewModel.didUpdateAmount(amount)

        XCTAssertEqual(mockUseCase.lastConvertedAmount, amount, "Use case should be called with updated amount")
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
        XCTAssertEqual(mockUseCase.lastConvertedAmount, mockUseCase.initialCurrencyValue, "Should call convertCurrency with initial value")
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
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: "5", .JPY: "150"])

        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, false)
        viewModel.didInputValidValue()
        // need trigger itemviewmodels update method
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: "5", .JPY: "150"])
        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, true)
    }

    func testDidResetInput() {
        let mockUseCase = MockCurrencyUseCase()
        let viewModel = CurrencyConvertViewModelImp(selectedIndex: 0, dependencies: .init(useCase: mockUseCase))
        mockUseCase.useCaseOutput = viewModel
        viewModel.didInputValidValue()
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: "5", .JPY: "150"])

        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, true)
        viewModel.didResetInput()
        // need trigger itemviewmodels update method
        mockUseCase.useCaseOutput?.didUpdateConvertResults([.USD: "5", .JPY: "150"])
        XCTAssertEqual(viewModel.itemViewModels[0].hasValidInput, false)
    }
}
