import Foundation

protocol CurrencyModuleEndpointsFactory {
    func currencyLatest() -> APIEndpoint<ExchangeData>
}

final class CurrencyModuleGenerator: CurrencyModuleEndpointsFactory {
    struct Dependencies {
        let networkInterceptor: [NetworkInterceptor]
    }

    private let dependencies: Dependencies
    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    private static let throttleInterval: TimeInterval = 30 * 60

    func currencyLatest() -> APIEndpoint<ExchangeData> {
        APIEndpoint<ExchangeData>(
            path: "latest.json",
            method: .get,
            queryParameters: ["base": "USD"],
            endpointRequestInterceptors: dependencies.networkInterceptor,
            endpointResponseInterceptors: dependencies.networkInterceptor,
            throttleInterval: CurrencyModuleGenerator.throttleInterval
        )
    }
}
