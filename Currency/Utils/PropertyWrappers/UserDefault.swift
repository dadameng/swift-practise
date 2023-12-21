import Foundation
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    var container: UserDefaults = .standard

    var wrappedValue: T {
        get {
            container.object(forKey: key) as? T ?? defaultValue
        }
        set {
            container.set(newValue, forKey: key)
            container.synchronize()
        }
    }
}
