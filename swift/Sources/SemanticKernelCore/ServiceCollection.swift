import Foundation

/// A very small service container keyed by type.
public actor ServiceCollection {
    private var services: [ObjectIdentifier: Any] = [:]

    public init() {}

    /// Register a service instance for its concrete type.
    public func add<T>(_ service: T) {
        let key = ObjectIdentifier(T.self)
        services[key] = service
    }

    /// Resolve a previously registered service.
    public func resolve<T>() -> T? {
        let key = ObjectIdentifier(T.self)
        return services[key] as? T
    }
}
