import Foundation

final class CurrencyRepositoryImp {
    struct Dependencies {
        let networkService: NetworkService
        let networkInterceptor: [NetworkInterceptor]
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension CurrencyRepositoryImp: CurrencyRepository {
    func fetchCurrencysLatest() -> FetchResult<ExchangeData> {
        let endpoint = APIEndpoints.currencyLatest(interceptor: dependencies.networkInterceptor)
        return dependencies.networkService.requestTask(endpoint: endpoint)
    }
}
