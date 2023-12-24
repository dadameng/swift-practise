import Foundation

protocol CurrencyConvertItemViewModel {
    var title: String { get }
    var currencyName: String { get }
    var valueString: String { get }
    var imageName: String { get }
    var selected: Bool { get }
    var hasValidInput: Bool { get }
    var isLoading: Bool { get }
}

@MainActor
struct CurrencyConvertItemViewModelImp: Equatable, CurrencyConvertItemViewModel {
    let title: String
    let currencyName: String
    let valueString: String
    let imageName: String
    let selected: Bool
    let hasValidInput: Bool
    let isLoading: Bool
}
