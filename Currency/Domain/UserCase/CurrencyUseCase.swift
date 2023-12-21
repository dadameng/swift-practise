import Combine
import Foundation

protocol CurrencyUseCaseCallback {
    func didUpdateSelectedSymbols(_ symblos: [Currency])
    func didUpdateConvertResults(_ convertResults: [Currency: String])
    func didLoadSuccess(_ convertResults: [Currency: String])
    func didLoadFailure(_ error: NetworkServiceError)
}

protocol CurrencyUseCase {
    var useCaseOutput: CurrencyUseCaseCallback? { get set }
    var initialCurrencyValue: String { get }
    var latestTimestamp: TimeInterval { get }
    var selectedSymbols: [Currency] { get }
    var convertResults: [Currency: String] { get }
    func updateSelectedSymbols(_ symbols: [Currency])
    func loadLatestCurrency()
    func convertCurrency(from: Currency, value: String)
    func cancelRequestLatestCurrency()
}

final class CurrencyConvertUseCaseImp {
    private let currencyRepository: CurrencyRepository
    var selectedSymbols: [Currency]
    var currentCurrency: Currency
    var currentCurrencyValue: String
    var initialCurrencyValue: String

    var useCaseOutputDelegate: CurrencyUseCaseCallback?
    var baseExchangeData: ExchangeData?
    var taskUseForCancel: Task<ExchangeData, Error>?
    var convertResults: [Currency: String] = [:]

    lazy var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .halfUp
        return formatter
    }()

    init(currencyRepository: CurrencyRepository, selectedSymbols: [Currency], currentCurrency: Currency, initialCurrencyValue: String) {
        self.currencyRepository = currencyRepository
        self.selectedSymbols = selectedSymbols
        self.currentCurrency = currentCurrency
        self.initialCurrencyValue = initialCurrencyValue
        currentCurrencyValue = initialCurrencyValue
    }
}

extension CurrencyConvertUseCaseImp: CurrencyUseCase {
    var latestTimestamp: TimeInterval {
        baseExchangeData?.timestamp ?? Date().timeIntervalSinceNow
    }

    var useCaseOutput: CurrencyUseCaseCallback? {
        get {
            useCaseOutputDelegate
        }
        set {
            useCaseOutputDelegate = newValue
        }
    }

    func cancelRequestLatestCurrency() {
        taskUseForCancel?.cancel()
    }

    func convertCurrency(from: Currency, value: String) {
        currentCurrencyValue = value
        privateConvertCurrency(from: from, value: value)
        useCaseOutput?.didUpdateConvertResults(convertResults)
    }

    func updateSelectedSymbols(_ symbols: [Currency]) {
        selectedSymbols = symbols
        privateConvertCurrency(from: currentCurrency, value: currentCurrencyValue)
        useCaseOutput?.didUpdateConvertResults(convertResults)
    }

    func loadLatestCurrency() {
        guard taskUseForCancel == nil else {
            taskUseForCancel?.cancel()
            return
        }
        let task = currencyRepository.fetchCurrencysLatest()
        taskUseForCancel = task
        Task.init {
            do {
                let exchangeData = try await task.value
                baseExchangeData = exchangeData
                privateConvertCurrency(from: currentCurrency, value: initialCurrencyValue)
                useCaseOutput?.didLoadSuccess(convertResults)
                taskUseForCancel = nil
            } catch let requestError as NetworkServiceError {
                useCaseOutput?.didLoadFailure(requestError)
                taskUseForCancel = nil
            }
        }
    }

    private func privateConvertCurrency(from: Currency, value: String) {
        guard let rates = baseExchangeData?.rates else { return }
        guard let rate = rates[from] else { return }
        let currentValue = Decimal(string: value) ?? Decimal(0)

        let baseAmount = currentValue / rate
        convertResults = selectedSymbols.reduce(into: [Currency: String]()) { result, currencyKey in
            if let currencyRate = rates[currencyKey] {
                let convertedValue = baseAmount * currencyRate
                result[currencyKey] = formatter.string(for: convertedValue)
            }
        }
    }
}
