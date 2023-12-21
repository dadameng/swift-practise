import Foundation

@MainActor
struct CurrencyConvertItemViewModel: Equatable {
    let title: String
    let currencyName: String
    let valueString: String
    let imageName: String
    let selected: Bool
    let hasValidInput: Bool
}
