import Foundation

protocol CurrencyListViewModelInput {
    func didSelectedIndex(at index: Int)
}

protocol CurrencyListViewModelOutput {
    var selectedSymbols: [Currency] { get }
    var listViewModels: [CurrencyListItemViewModel] { get }
}

typealias CurrencyListViewModel = CurrencyListViewModelInput & CurrencyListViewModelOutput

@MainActor
final class CurrencyListViewModelImp {
    struct Dependencies {
        var currentSymbols: [Currency]
        var initialChangeIndex: Int
    }

    private let dependencies: Dependencies
    let allCurrencies = Array(CurrencyDesciption.descriptions.keys).sorted { $0.rawValue < $1.rawValue }

    var selectedSymbols: [Currency]
    var listViewModels: [CurrencyListItemViewModel]
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        selectedSymbols = dependencies.currentSymbols
        listViewModels = allCurrencies.map { currency in
            CurrencyListItemViewModel(
                currency: currency.rawValue,
                imageName: currency.rawValue.lowercased(),
                selected: dependencies.currentSymbols.contains(currency)
            )
        }
    }
}

extension CurrencyListViewModelImp: CurrencyListViewModel {
    func didSelectedIndex(at index: Int) {
        selectedSymbols[dependencies.initialChangeIndex] = allCurrencies[index]
    }
}
