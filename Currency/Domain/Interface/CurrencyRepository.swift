import Foundation

protocol CurrencyRepository {
    func fetchCurrencysLatest() -> FetchResult<ExchangeData>
}
