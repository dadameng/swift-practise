import Foundation

enum APIEndpoints {
    static func currencyLatest(interceptor: [NetworkInterceptor]) -> APIEndpoint<ExchangeData> {
        APIEndpoint<ExchangeData>(
            path: "latest.json",
            method: .get,
            queryParameters: ["base": "USD"],
            endpointRequestInterceptors: interceptor,
            endpointResponseInterceptors: interceptor
        )
    }
}
