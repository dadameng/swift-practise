# iOS Currency Application

## Key Features

### Currency Conversion List
- **Overview**: The app includes a currency conversion list featuring five countries: the United States, Japan, China, Hong Kong, and Taiwan.
- **Design Choice**: To ensure a visually appealing layout, the list is limited to five currencies.
- **Functionality**: Users input a value in their current currency. The app then calculates the equivalent in the selected currencies using rates from the Open Exchange Rates API. It accurately displays conversion results up to three decimal places.

### Rate List Modification
- **Interactive Element**: The app allows users to interactively modify the exchange rate list. By swiping left on a rate list cell, users can change the displayed exchange rate to a different country's currency.
- **Data Handling**: The list of countries with their respective exchange rates is pre-loaded and fixed, enhancing both performance and the user interface. This approach is chosen over dynamically fetching data from the API for each request.


## Project Organization

```
├── Application
    │   ├── DIContainer
    │   ├── AppDelegate.swift
    │   ├── AppNetworkConfiguration.swift
    │   ├── AppRouter.swift
    │   └── SceneDelegate.swift
    ├── Data
    │   ├── Network
    │   └── Repository
    ├── Domain
    │   ├── Entitity
    │   ├── Interface
    │   └── UserCase
    ├── Infrastructure
    │   └── Network
    ├── Presentation
    │   ├── Behaviors
    │   ├── CurrencyConvert
    │   ├── CurrencyList
    │   └── FlowCoordinator
    ├── Utils
    │   ├── PropertyWrappers
    │   ├── AppColor.swift
    │   └── String+MD5.swift
```

### Application
- **Main Functionality**: This section primarily handles the program loading and the construction of the Dependency Injection (DI) container.
- **Design Decision**: To avoid dependency on third-party frameworks, the project does not utilize a DI framework.

### Data
- **Currency Rate Loading Logic**: The logic for loading exchange rates is housed here. 
- **Request Throttling**: The app checks if the time elapsed since the last request exceeds a 30-minute threshold. If it hasn't, or if no prior request was made, a network request is initiated. Otherwise, data is fetched from the cache.
- **Cache Design**: Inspired by the SDWebImage library, a two-layer caching system (memory and disk caches) is implemented. The caches are cleared under memory pressure, and the disk cache adheres to the Least Recently Used (LRU) algorithm for maintenance.

### Domain
#### Currency and CurrencyDescription Structures
- **Functionality**: 
  - **Currency**: Defines currency types in a type-safe manner, using `RawRepresentable`, `Codable`, and `Hashable` for efficient handling. Each currency is a static constant (e.g., `Currency(rawValue: "USD")`), ensuring ease of use and consistency.
  - **CurrencyDescription**: Provides a static dictionary that maps `Currency` instances to their descriptive strings (e.g., `.USD: "United States Dollar"`), aiding in readability and localization.
#### Use of @DictionaryWrapper
- **Codable Compatibility**: Tackles the limitation in Swift's `Codable` protocol, which does not natively support dictionaries with custom types (like `Currency`) as keys.
- **Encoding/Decoding Issue**: Swift's `Codable` faces challenges when encoding and decoding dictionaries with non-standard keys. As discussed in the [Swift Forum](https://forums.swift.org/t/using-rawrepresentable-string-and-int-keys-for-codable-dictionaries/26899/13), without a workaround like `@DictionaryWrapper`, the process would fail for custom key types.
- **Solution Implementation**: `@DictionaryWrapper` is used to properly serialize and deserialize the `rates` dictionary, ensuring correct handling of the custom `Currency` type.


#### Advantages
- **Precision and Accuracy**: Utilization of `Decimal` for financial calculations eliminates floating-point errors, crucial for currency exchange data.
- **Type Safety and Readability**: The strong typing of currency codes enhances code safety and clarity.

### Infrastructure
- **Network Requests**: Utilizes Swift's Concurrency features.
- **Loose Coupling**: Implemented using the Interceptor pattern, allowing for modular and maintainable code. This setup integrates caching functionality with URLCache for efficient data retrieval and management.

### Presentation
- **Core Presentation Logic**: This directory contains the primary presentation layer logic, including the main list interfaces for displaying currency conversation list.
- **User Interface**: Focuses on delivering a smooth and user-friendly interface for the key features of the app, including the currency conversion list and rate list modification functionality.

### Utils
- **Utility Functions**: Contains auxiliary functions and code for handling property wrappers.
- **Purpose**: These utilities aid in streamlining common tasks and enhancing code reusability throughout the project, ensuring a cleaner and more maintainable codebase.





