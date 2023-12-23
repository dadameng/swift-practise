import UIKit

protocol CurrencyConvertDIContainer {
    func makeCurrencyConvertViewController() -> UIViewController
}

final class CurrencyConvertDIContainerImp {
    struct Dependencies {
        let apiDataTransferService: NetworkService
        let navigationController: UINavigationController
        unowned let appDIContainer: AppDIContainer
    }

    private enum CacheConfiguration {
        static let maxCacheAge = 60 * 60 * 24 * 7 // 1week
        static let maxMemoryCost = 10 * 1024 * 1024 // 10MB
        static let maxCacheSize = 20 * 1024 * 1024 // 20MB
    }

    private static let initialSelectedSymbols: [Currency] = [.USD, .JPY, .CNY, .HKD, .TWD]
    private static let initialCurrencyValue = Decimal(100)

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func makeCurrencyConvertAPICache() -> APICache {
        DefaultAPICache(
            maxCacheAge: TimeInterval(CacheConfiguration.maxCacheAge),
            maxMemoryCost: CacheConfiguration.maxMemoryCost,
            maxCacheSize: CacheConfiguration.maxCacheSize,
            memCache: NSCache(),
            diskEncoder: JSONResponseEncoder(),
            diskDecoder: JSONResponseDecoder()
        )
    }

    func makeCurrencyConvertRepository(_ apiService: NetworkService) -> CurrencyRepository {
        let cache = makeCurrencyConvertAPICache()
        let endpointsFactory = CurrencyModuleGenerator(dependencies: .init(networkInterceptor: [CacheInterceptor(cache: cache)]))
        return CurrencyRepositoryImp(dependencies: .init(
            networkService: apiService,
            apiCache: cache,
            endpointsFactory: endpointsFactory
        ))
    }

    func makeCurrencyConvertUserCase(_ repository: CurrencyRepository) -> CurrencyUseCase {
        CurrencyConvertUseCaseImp(
            currencyRepository: repository,
            selectedSymbols: CurrencyConvertDIContainerImp.initialSelectedSymbols,
            currentCurrency: .USD,
            initialCurrencyValue: CurrencyConvertDIContainerImp.initialCurrencyValue
        )
    }

    @MainActor func makeCurrencyConvertViewModel(_ useCase: CurrencyUseCase) -> CurrencyConvertViewModel {
        CurrencyConvertViewModelImp(
            selectedIndex: 0,
            dependencies: CurrencyConvertViewModelImp.Dependencies(useCase: useCase)
        )
    }

    func makeCurrencyConvertCoordinator() -> CurrencyConvertCoordinator {
        CurrencyConvertCoordinatorImp()
    }
}

extension CurrencyConvertDIContainerImp: CurrencyConvertDIContainer {
    @MainActor func makeCurrencyConvertViewController() -> UIViewController {
        let repository = makeCurrencyConvertRepository(dependencies.apiDataTransferService)
        var useCase = makeCurrencyConvertUserCase(repository)
        let viewModel = makeCurrencyConvertViewModel(useCase)
        useCase.useCaseOutput = viewModel
        return CurrencyConvertController(coordinator: makeCurrencyConvertCoordinator(), viewModel: viewModel)
    }
}
