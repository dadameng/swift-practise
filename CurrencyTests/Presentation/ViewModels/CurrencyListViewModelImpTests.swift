@testable import Currency
import XCTest

@MainActor
final class CurrencyListViewModelImpTests: XCTestCase {
    func testCurrencyListViewModelInitialisation() {
        let dependencies = CurrencyListViewModelImp.Dependencies(currentSymbols: [.USD, .EUR], initialChangeIndex: 0)
        let viewModel = CurrencyListViewModelImp(dependencies: dependencies)

        XCTAssertEqual(
            viewModel.listViewModels.count,
            CurrencyDesciption.descriptions.count,
            "List view models should be equal to the number of currencies"
        )
        XCTAssertTrue(viewModel.listViewModels.contains { $0.currency == "USD" && $0.selected }, "USD should be marked as selected")
        XCTAssertTrue(viewModel.listViewModels.contains { $0.currency == "EUR" && $0.selected }, "EUR should be marked as selected")
    }

    func testDidSelectIndex() {
        let dependencies = CurrencyListViewModelImp.Dependencies(currentSymbols: [.USD, .EUR], initialChangeIndex: 0)
        let viewModel = CurrencyListViewModelImp(dependencies: dependencies)
        let selectedIndex = viewModel.allCurrencies.firstIndex(of: .JPY)!

        viewModel.didSelectedIndex(at: selectedIndex)

        XCTAssertEqual(viewModel.selectedSymbols[0], .JPY, "Selected symbols should now contain JPY at the initial change index")
    }
}
