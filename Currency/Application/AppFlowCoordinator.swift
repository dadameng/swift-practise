import UIKit


protocol AppBaseFlowCoordinator : AnyObject {
    func setupRootViewController(on window: UIWindow)
}

typealias AppFlowCoordinator = AppBaseFlowCoordinator & CurrencyConvertCoordinator

final class AppFlowCoordinatorImp {
    struct Dependencies {
        let appDIContainer: AppDIContainer
    }
    private let dependencies: Dependencies
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
}

extension AppFlowCoordinatorImp: AppFlowCoordinator  {
    // MARK: - AppBaseFlowCoordinator
    func setupRootViewController(on window: UIWindow) {
        let navigationViewController = UINavigationController()

        let currencyConvertDIContainer = dependencies.appDIContainer.makeConvertDIContainer(appFlowCoordinator: self, navigationController: navigationViewController)
        let currencyConvertViewController = currencyConvertDIContainer.makeCurrencyConvertViewController()
        navigationViewController.viewControllers = [currencyConvertViewController]
        window.rootViewController = navigationViewController
    }
    
    // MARK: - CurrencyConvertCoordinator
    func showCurrencyListViewController(
        from navigationController: UINavigationController,
        in symbols: [Currency],
        at index: Int,
        symbolsChangeBlock: @escaping ([Currency]) -> Void
    ) {
        let listDIContainer = dependencies.appDIContainer.makeListDIContainer(appFlowCoordinator: self, navigationController: navigationController)
        let listVC = listDIContainer.makeCurrencyListtViewController(in: symbols, at: index, symbolsChangeBlock: symbolsChangeBlock)
        navigationController.pushViewController(listVC, animated: true)
    }
}
