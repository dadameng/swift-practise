import UIKit

final class AppDIContainer {
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

    func makeConvertDIContainer(navigationController: UINavigationController) -> CurrencyConvertDIContainer {
        let dependencies = CurrencyConvertDIContainerImp.Dependencies(
            apiDataTransferService: apiDataTransferService,
            navigationController: navigationController, appDIContainer: self
        )
        return CurrencyConvertDIContainerImp(dependencies: dependencies)
    }

    func makeListDIContainer(navigationController: UINavigationController) -> CurrencyListDIContainer {
        let dependencies = CurrencyListDIContainerImp.Dependencies(
            apiDataTransferService: apiDataTransferService,
            navigationController: navigationController,
            appDIContainer: self
        )
        return CurrencyListDIContainerImp(dependencies: dependencies)
    }
}
