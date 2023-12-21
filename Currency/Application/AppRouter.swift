import Foundation
import UIKit

final class AppRouter {
    static let shared = AppRouter()
    let appDIContainer = AppDIContainer()
    private init() {}

    func setupRootViewController(on window: UIWindow) {
        let navigationViewController = UINavigationController()

        let currencyConvertDIContainer = appDIContainer.makeConvertDIContainer(navigationController: navigationViewController)
        let currencyConvertViewController = currencyConvertDIContainer.makeCurrencyConvertViewController()
        navigationViewController.viewControllers = [currencyConvertViewController]
        window.rootViewController = navigationViewController
    }
}

extension AppRouter: CurrencyConvertCoordinator {
    func showCurrencyListViewController(
        from navigationController: UINavigationController,
        in symbols: [Currency],
        at index: Int,
        symbolsChangeBlock: @escaping ([Currency]) -> Void
    ) {
        let listDIContainer = appDIContainer.makeListDIContainer(navigationController: navigationController)
        let listVC = listDIContainer.makeCurrencyListtViewController(in: symbols, at: index, symbolsChangeBlock: symbolsChangeBlock)
        navigationController.pushViewController(listVC, animated: true)
    }
}
