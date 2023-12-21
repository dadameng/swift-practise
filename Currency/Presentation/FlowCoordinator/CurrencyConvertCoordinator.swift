import UIKit

protocol CurrencyConvertCoordinator {
    func showCurrencyListViewController(
        from navigationController: UINavigationController,
        in symbols: [Currency],
        at index: Int,
        symbolsChangeBlock: @escaping ([Currency]) -> Void
    )
}

final class CurrencyConvertCoordinatorImp {}

extension CurrencyConvertCoordinatorImp: CurrencyConvertCoordinator {
    func showCurrencyListViewController(
        from navigationController: UINavigationController,
        in symbols: [Currency],
        at index: Int,
        symbolsChangeBlock: @escaping ([Currency]) -> Void
    ) {
        AppRouter.shared.showCurrencyListViewController(
            from: navigationController,
            in: symbols,
            at: index,
            symbolsChangeBlock: symbolsChangeBlock
        )
    }
}
