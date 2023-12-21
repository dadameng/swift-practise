import UIKit

protocol CurrencyListCoordinator {
    func popToSource(_ symbols: [Currency], from navigationViewController: UINavigationController)
}

final class CurrencyListCoordinatorImp {
    let symbolsChangeBlock: ([Currency]) -> Void

    init(symbolsChangeBlock: @escaping ([Currency]) -> Void) {
        self.symbolsChangeBlock = symbolsChangeBlock
    }
}

extension CurrencyListCoordinatorImp: CurrencyListCoordinator {
    func popToSource(_ symbols: [Currency], from navigationViewController: UINavigationController) {
        symbolsChangeBlock(symbols)
        navigationViewController.popViewController(animated: true)
    }
}
