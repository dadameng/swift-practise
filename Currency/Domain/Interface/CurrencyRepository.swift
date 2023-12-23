import Foundation

protocol CurrencyRepository {
    func fetchLatestCurrencies() -> FetchResult<ExchangeData>
    func fetchCurrencies() -> FetchResult<ExchangeData>
}
