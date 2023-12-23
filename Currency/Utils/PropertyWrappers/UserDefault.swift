import Foundation
@propertyWrapper
struct UserDefault<T> {
    let key: String
    var storage: UserDefaults
    var defaultValue: T

    var wrappedValue: T {
        get {
            return storage.object(forKey: key) as? T ?? defaultValue
        }
        set {
            storage.set(newValue, forKey: key)
        }
    }

    init(key: String, defaultValue: T, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }
}
