import Foundation

extension Dictionary {
    @inlinable
    @inline(__always)
    internal mutating func modifyValue<R>(
        forKey key: Key,
        default defaultValue: @autoclosure () -> Value,
        _ modifications: (inout Value) throws -> R
    ) rethrows -> R {
        try modifications(&self[key, default: defaultValue()])
    }

    @inlinable
    @inline(__always)
    internal mutating func modifyValue<R>(
        forKey key: Key,
        _ modifications: (inout Value?) throws -> R
    ) rethrows -> R {
        try modifications(&self[key])
    }
}
