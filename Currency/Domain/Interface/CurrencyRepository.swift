import Foundation

protocol CurrencyRepository {
    func fetchLatestCurrencys() -> FetchResult<ExchangeData>
    func fetchCurrencys() -> FetchResult<ExchangeData>
}
