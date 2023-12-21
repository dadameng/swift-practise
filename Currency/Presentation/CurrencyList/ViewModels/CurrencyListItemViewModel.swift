import Foundation
@MainActor
struct CurrencyListItemViewModel: Equatable {
    let currency: String
    let imageName: String
    let selected: Bool
}
