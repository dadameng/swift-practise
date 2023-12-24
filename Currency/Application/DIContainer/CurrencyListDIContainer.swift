import Foundation
import UIKit

protocol CurrencyListDIContainer {
    func makeCurrencyListtViewController(in symbols: [Currency], at index: Int, symbolsChangeBlock: @escaping ([Currency]) -> Void)
        -> UIViewController
}

final class CurrencyListDIContainerImp {
    struct Dependencies {
        let apiDataTransferService: NetworkService
        let navigationController: UINavigationController
        unowned let appRouterFlowCoordinator: AppFlowCoordinator
    }

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    @MainActor func makeCurrencyListtViewModel(_ symbols: [Currency], at index: Int) -> CurrencyListViewModel {
        CurrencyListViewModelImp(dependencies: .init(currentSymbols: symbols, initialChangeIndex: index))
    }

    func makeCurrencyListCoordinator(block: @escaping ([Currency]) -> Void) -> CurrencyListCoordinator {
        CurrencyListCoordinatorImp(symbolsChangeBlock: block)
    }
}

extension CurrencyListDIContainerImp: CurrencyListDIContainer {
    @MainActor func makeCurrencyListtViewController(
        in symbols: [Currency],
        at index: Int,
        symbolsChangeBlock: @escaping ([Currency]) -> Void
    ) -> UIViewController {
        let coordinator = makeCurrencyListCoordinator(block: symbolsChangeBlock)
        let viewModel = makeCurrencyListtViewModel(symbols, at: index)
        return CurrencyListController(coordinator: coordinator, viewModel: viewModel)
    }
}
