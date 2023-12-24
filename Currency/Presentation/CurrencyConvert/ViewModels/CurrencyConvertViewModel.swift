import Combine
import UIKit

enum CurrencyConvertViewModelOutputError: Error {
    case requestFailure(String)
}

protocol CurrencyConvertViewModelInput: ViewControllerLifecycleBehavior, CurrencyUseCaseCallback {
    func didUpdateAmount(_ amount: String?)
    func didTriggerRefresh()
    func didSelectItem(at index: Int)
    func didInputValidValue()
    func didResetInput()
}

protocol CurrencyConvertViewModelOutput {
    var formatteMaximumFractionDigits: Int { get }
    var itemViewModels: [CurrencyConvertItemViewModel] { get }
    var lastTimeString: String { get }
    var selectedSymbols: [Currency] { get }
    var selectedIndex: Int { get }
    var isRequestingPublisher: AnyPublisher<Bool, Never> { get }
    var itemViewModelsPublisher: AnyPublisher<
        Result<[CurrencyConvertItemViewModel], CurrencyConvertViewModelOutputError>,
        Never
    > { get }
}

typealias CurrencyConvertViewModel = CurrencyConvertViewModelInput & CurrencyConvertViewModelOutput

@MainActor
final class CurrencyConvertViewModelImp: ObservableObject {
    struct Dependencies {
        let useCase: CurrencyUseCase
    }

    var selectedIndex: Int {
        didSet {
            let maxIndex = dependencies.useCase.selectedSymbols.count - 1
            if selectedIndex < 0 || selectedIndex > maxIndex {
                selectedIndex = oldValue
            }
        }
    }

    @Published private var isRequesting: Bool = false
    var formatteMaximumFractionDigits = 3

    private var currentInput: String = ""
    private var internalItemViewModels: [CurrencyConvertItemViewModel] = []
    private var keyboardHasValidInput = false
    private let dependencies: Dependencies
    private var successSubject = PassthroughSubject<[CurrencyConvertItemViewModel], Never>()
    private var failureSubject = PassthroughSubject<CurrencyConvertViewModelOutputError, Never>()

    init(selectedIndex: Int, dependencies: Dependencies) {
        self.selectedIndex = selectedIndex
        self.dependencies = dependencies
        currentInput = "\(dependencies.useCase.initialCurrencyValue)"
    }

    private lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = formatteMaximumFractionDigits
        formatter.roundingMode = .halfUp
        return formatter
    }()

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "JST")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        return dateFormatter.string(from: date)
    }

    private func updateItemViewModels() {
        internalItemViewModels = dependencies.useCase.selectedSymbols.enumerated()
            .map { [unowned self] index, currency in
                CurrencyConvertItemViewModelImp(
                    title: currency.rawValue,
                    currencyName: CurrencyDesciption.descriptions[currency]!,
                    valueString: selectedIndex == index ? currentInput : formatter.string(for: dependencies.useCase.convertResults[currency])!,
                    imageName: currency.rawValue.lowercased(),
                    selected: selectedIndex == index,
                    hasValidInput: keyboardHasValidInput,
                    isLoading: isRequesting
                )
            }
        successSubject.send(internalItemViewModels)
    }

    private func loadInitialData() {
        isRequesting = true
        dependencies.useCase.loadCurrency()
        updateItemViewModels()
    }
}

extension CurrencyConvertViewModelImp: CurrencyConvertViewModel {
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

    func didUpdateConvertResults(_: [Currency: Decimal]) {
        updateItemViewModels()
    }

    func didLoadSuccess(_: [Currency: Decimal]) {
        isRequesting = false
        updateItemViewModels()
    }

    func didLoadFailure(_ error: NetworkServiceError) {
        isRequesting = false
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
            case .invalidData:
                internalLoadLatestError = "no valid contents"
            case .notConnected:
                internalLoadLatestError = "please check your network"
            case let .error(statusCode, _):
                internalLoadLatestError = "reponse error code : \(statusCode)"
            case .notHttpResponse:
                internalLoadLatestError = "please make sure you are sending http request"
            }
        }
        failureSubject.send(.requestFailure(internalLoadLatestError))
    }

    var itemViewModels: [CurrencyConvertItemViewModel] {
        internalItemViewModels
    }

    func cancelRequestLatestCurrency() {
        dependencies.useCase.cancelRequestLatestCurrency()
    }

    var isRequestingPublisher: AnyPublisher<Bool, Never> {
        $isRequesting.eraseToAnyPublisher()
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

    func didUpdateAmount(_ amount: String?) {
        currentInput = amount ?? "0"
        guard let decimalAmount = Decimal(string: currentInput),
              decimalAmount != dependencies.useCase.currentCurrencyValue ||
              selectedSymbols[selectedIndex] != dependencies.useCase.currentCurrency
        else {
            updateItemViewModels()
            return
        }

        dependencies.useCase.convertCurrency(
            from: dependencies.useCase.selectedSymbols[selectedIndex],
            value: decimalAmount
        )
    }

    func didTriggerRefresh() {
        isRequesting = true
        dependencies.useCase.refreshCurrency()
    }

    func didSelectItem(at index: Int) {
        selectedIndex = index
        didUpdateAmount("\(dependencies.useCase.initialCurrencyValue)")
    }
}

extension CurrencyConvertViewModelImp: ViewControllerLifecycleBehavior {
    func viewDidLoad(viewController _: UIViewController) {
        loadInitialData()
    }
}
