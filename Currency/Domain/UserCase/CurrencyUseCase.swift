import Combine
import Foundation

protocol CurrencyUseCaseCallback {
    func didUpdateSelectedSymbols(_ symblos: [Currency])
    func didUpdateConvertResults(_ convertResults: [Currency: Decimal])
    func didLoadSuccess(_ convertResults: [Currency: Decimal])
    func didLoadFailure(_ error: NetworkServiceError)
}

protocol CurrencyUseCase {
    var useCaseOutput: CurrencyUseCaseCallback? { get set }
    var initialCurrencyValue: Decimal { get }
    var currentCurrencyValue: Decimal { get }
    var latestTimestamp: TimeInterval { get }
    var selectedSymbols: [Currency] { get }
    var currentCurrency: Currency { get }
    var convertResults: [Currency: Decimal] { get }
    func updateSelectedSymbols(_ symbols: [Currency])
    func refreshLatestCurrency()
    func loadCurrency()
    func convertCurrency(from: Currency, value: Decimal)
    func cancelRequestLatestCurrency()
}

final class CurrencyConvertUseCaseImp {
    private let currencyRepository: CurrencyRepository
    var selectedSymbols: [Currency]
    var currentCurrency: Currency
    var currentCurrencyValue: Decimal
    var initialCurrencyValue: Decimal

    var useCaseOutputDelegate: CurrencyUseCaseCallback?
    var baseExchangeData: ExchangeData?
    var taskUseForCancel: Task<ExchangeData, Error>?
    var convertResults: [Currency: Decimal]

    init(currencyRepository: CurrencyRepository, selectedSymbols: [Currency], currentCurrency: Currency, initialCurrencyValue: Decimal) {
        self.currencyRepository = currencyRepository
        self.selectedSymbols = selectedSymbols
        self.currentCurrency = currentCurrency
        self.initialCurrencyValue = initialCurrencyValue
        currentCurrencyValue = initialCurrencyValue
        convertResults = Dictionary(uniqueKeysWithValues: selectedSymbols.map { ($0, Decimal(0)) })
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

    func convertCurrency(from: Currency, value: Decimal) {
        currentCurrencyValue = value
        privateConvertCurrency(from: from, value: currentCurrencyValue)
        useCaseOutput?.didUpdateConvertResults(convertResults)
    }

    func updateSelectedSymbols(_ symbols: [Currency]) {
        selectedSymbols = symbols
        privateConvertCurrency(from: currentCurrency, value: currentCurrencyValue)
        useCaseOutput?.didUpdateConvertResults(convertResults)
    }

    func refreshLatestCurrency() {
        let task = currencyRepository.fetchLatestCurrencys()
        executeCurrencyTask(task, withInitialValue: currentCurrencyValue)
    }

    func loadCurrency() {
        let task = currencyRepository.fetchCurrencys()
        executeCurrencyTask(task, withInitialValue: initialCurrencyValue)
    }
    
    private func executeCurrencyTask(_ task: FetchResult<ExchangeData>, withInitialValue initialValue: Decimal) {
        guard taskUseForCancel == nil else {
            taskUseForCancel?.cancel()
            return
        }
        taskUseForCancel = task
        Task.init {
            do {
                let exchangeData = try await task.value
                baseExchangeData = exchangeData
                privateConvertCurrency(from: currentCurrency, value: initialValue)
                useCaseOutput?.didLoadSuccess(convertResults)
                taskUseForCancel = nil
            } catch let requestError as NetworkServiceError {
                useCaseOutput?.didLoadFailure(requestError)
                taskUseForCancel = nil
            }
        }
    }

    private func privateConvertCurrency(from: Currency, value: Decimal) {
        guard let rates = baseExchangeData?.rates else { return }
        guard let rate = rates[from] else { return }
        let currentValue = value

        let baseAmount = currentValue / rate
        convertResults = selectedSymbols.reduce(into: [Currency: Decimal]()) { result, currencyKey in
            if let currencyRate = rates[currencyKey] {
                let convertedValue = baseAmount * currencyRate
                result[currencyKey] = convertedValue
            }
        }
    }
}
