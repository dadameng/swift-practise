import UIKit

protocol CurrencyConvertCoordinator {
    func showCurrencyListViewController(
        from navigationController: UINavigationController,
        in symbols: [Currency],
        at index: Int,
        symbolsChangeBlock: @escaping ([Currency]) -> Void
    )
}

final class CurrencyConvertCoordinatorImp {
    struct Dependencies {
        unowned let appRouterFlowCoordinator: AppFlowCoordinator
    }
    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
}

extension CurrencyConvertCoordinatorImp: CurrencyConvertCoordinator {
    func showCurrencyListViewController(
        from navigationController: UINavigationController,
        in symbols: [Currency],
        at index: Int,
        symbolsChangeBlock: @escaping ([Currency]) -> Void
    ) {
        dependencies.appRouterFlowCoordinator.showCurrencyListViewController(
            from: navigationController,
            in: symbols,
            at: index,
            symbolsChangeBlock: symbolsChangeBlock
        )
    }
}
