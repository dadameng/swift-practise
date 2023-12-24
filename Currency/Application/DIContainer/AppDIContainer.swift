import UIKit

protocol AppDIContainer {
    func makeConvertDIContainer(router: AppRouterFlowCoordinator, navigationController: UINavigationController) -> CurrencyConvertDIContainer
    func makeListDIContainer(router: AppRouterFlowCoordinator, navigationController: UINavigationController) -> CurrencyListDIContainer
}

final class AppDIContainerImp : AppDIContainer {
    private lazy var appConfiguration = AppNetworkConfiguration()
    private lazy var apiDataTransferService: NetworkService = {
        let config = ApiDataNetworkConfig(
            baseURL: URL(string: appConfiguration.apiBaseURL)!,
            queryParameters: [
                "app_id": appConfiguration.apiKey,
                "language": NSLocale.preferredLanguages.first ?? "en",
            ]
        )

        return DefaultNetworkService(config: config)
    }()

    func makeConvertDIContainer(router: AppRouterFlowCoordinator, navigationController: UINavigationController) -> CurrencyConvertDIContainer {
        let dependencies = CurrencyConvertDIContainerImp.Dependencies(
            apiDataTransferService: apiDataTransferService,
            navigationController: navigationController,
            appRouterFlowCoordinator: router
        )
        return CurrencyConvertDIContainerImp(dependencies: dependencies)
    }

    func makeListDIContainer(router: AppRouterFlowCoordinator, navigationController: UINavigationController) -> CurrencyListDIContainer {
        let dependencies = CurrencyListDIContainerImp.Dependencies(
            apiDataTransferService: apiDataTransferService,
            navigationController: navigationController,
            appRouterFlowCoordinator: router
        )
        return CurrencyListDIContainerImp(dependencies: dependencies)
    }
}
