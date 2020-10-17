import Foundation

extension MutableCollection {
    @inlinable
    @inline(__always)
    internal mutating func modifyElement<R>(
        at index: Index,
        _ modifications: (inout Element) throws -> R
    ) rethrows -> R {
        return try modifications(&self[index])
    }
}
