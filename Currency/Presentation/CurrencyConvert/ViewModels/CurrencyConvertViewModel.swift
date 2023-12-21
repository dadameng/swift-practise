import Combine
import UIKit

enum CurrencyConvertViewModelOutputError: Error {
    case requestFailure(String)
}

protocol CurrencyConvertViewModelInput: ViewControllerLifecycleBehavior, CurrencyUseCaseCallback {
    func didUpdateAmount(_ amount: String)
    func didTriggerRefresh()
    func didSelectItem(at index: Int)
    func willChangeItem(_ value: String)
    func didInputValidValue()
    func didResetInput()
}

protocol CurrencyConvertViewModelOutput {
    var itemViewModels: [CurrencyConvertItemViewModel] { get }
    var lastTimeString: String { get }
    var selectedSymbols: [Currency] { get }
    var selectedIndex: Int { get }
    var itemViewModelsPublisher: AnyPublisher<
        Result<[CurrencyConvertItemViewModel], CurrencyConvertViewModelOutputError>,
        Never
    > { get }
}

typealias CurrencyConvertViewModel = CurrencyConvertViewModelInput & CurrencyConvertViewModelOutput

@MainActor
final class CurrencyConvertViewModelImp {
    struct Dependencies {
        let useCase: CurrencyUseCase
    }

    private var internalItemViewModels: [CurrencyConvertItemViewModel] = []
    var selectedIndex: Int {
        didSet {
            let maxIndex = dependencies.useCase.selectedSymbols.count - 1
            if selectedIndex < 0 || selectedIndex > maxIndex {
                selectedIndex = oldValue
            }
        }
    }

    private var keyboardHasValidInput = false

    private var cancelToken: NetworkCancellable?
    private let dependencies: Dependencies

    private var successSubject = PassthroughSubject<[CurrencyConvertItemViewModel], Never>()
    private var failureSubject = PassthroughSubject<CurrencyConvertViewModelOutputError, Never>()

    init(selectedIndex: Int, dependencies: Dependencies) {
        self.selectedIndex = selectedIndex
        self.dependencies = dependencies
    }

    func updateItemViewModels(_ convertResults: [Currency: String]) {
        internalItemViewModels = dependencies.useCase.selectedSymbols.enumerated()
            .map { [unowned self] index, currency in
                CurrencyConvertItemViewModel(
                    title: currency.rawValue,
                    currencyName: CurrencyDesciption.descriptions[currency]!,
                    valueString: convertResults[currency]!,
                    imageName: currency.rawValue.lowercased(),
                    selected: selectedIndex == index,
                    hasValidInput: keyboardHasValidInput
                )
            }
        successSubject.send(internalItemViewModels)
    }
}

extension CurrencyConvertViewModelImp: CurrencyConvertViewModel {
    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "JST")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    var lastTimeString: String {
        formatTimestamp(dependencies.useCase.latestTimestamp)
    }

    var selectedSymbols: [Currency] {
        dependencies.useCase.selectedSymbols
    }

    func didResetInput() {
        keyboardHasValidInput = false
    }

    func didInputValidValue() {
        keyboardHasValidInput = true
    }

    func didUpdateSelectedSymbols(_ symblos: [Currency]) {
        dependencies.useCase.updateSelectedSymbols(symblos)
    }

    func didUpdateConvertResults(_ convertResults: [Currency: String]) {
        updateItemViewModels(convertResults)
    }

    func didLoadSuccess(_ convertResults: [Currency: String]) {
        updateItemViewModels(convertResults)
    }

    func didLoadFailure(_ error: NetworkServiceError) {
        var internalLoadLatestError = ""
        switch error {
        case let .generic(genericError):
            internalLoadLatestError = genericError.localizedDescription
        case .requestFailure:
            internalLoadLatestError = "invalid path"
        case let .responseFailure(responseError):
            switch responseError {
            case .cancelled:
                internalLoadLatestError = "canceld"
            case .decodeError:
                internalLoadLatestError = "invalid data, please contact the custom service"
            case .noResponse:
                internalLoadLatestError = "no contents"
            case .notConnected:
                internalLoadLatestError = "please check your network"
            case let .error(statusCode, _):
                internalLoadLatestError = "reponse error code : \(statusCode)"
            }
        }
        failureSubject.send(.requestFailure(internalLoadLatestError))
    }

    var itemViewModels: [CurrencyConvertItemViewModel] {
        internalItemViewModels
    }

    func cancelRequestLatestCurrency() {
        cancelToken?.cancel()
    }

    var itemViewModelsPublisher: AnyPublisher<
        Result<[CurrencyConvertItemViewModel], CurrencyConvertViewModelOutputError>,
        Never
    > {
        Publishers.Merge(
            successSubject.map { .success($0) },
            failureSubject.map { .failure($0) }
        )
        .eraseToAnyPublisher()
    }

    func didUpdateAmount(_ amount: String) {
        dependencies.useCase.convertCurrency(
            from: dependencies.useCase.selectedSymbols[selectedIndex],
            value: amount
        )
    }

    func didTriggerRefresh() {
        dependencies.useCase.loadLatestCurrency()
    }

    func willChangeItem(_: String) {}

    func didSelectItem(at index: Int) {
        selectedIndex = index
        didUpdateAmount(dependencies.useCase.initialCurrencyValue)
    }
}

extension CurrencyConvertViewModelImp: ViewControllerLifecycleBehavior {
    func viewDidLoad(viewController _: UIViewController) {
        loadInitialData()
    }

    private func loadInitialData() {
        dependencies.useCase.loadLatestCurrency()
    }
}
