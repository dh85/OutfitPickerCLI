import Foundation

/// Thread-safe wrapper for mutable state in test doubles.
final class Locked<T>: @unchecked Sendable {
    private var _value: T
    private let lock = NSLock()
    
    init(_ value: T) {
        self._value = value
    }
    
    var value: T {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }
    
    func withValue<R>(_ body: (inout T) -> R) -> R {
        lock.lock()
        defer { lock.unlock() }
        return body(&_value)
    }
}
