import Foundation

extension Optional {
    @inlinable
    @inline(__always)
    internal mutating func modifyIfNotNil(
        _ modifications: (inout Wrapped) throws -> Void
    ) rethrows {
        // We extract the value out of self, or return early:
        guard var value = self else { return }
        
        // Then we clear the remaining use in `self`,
        // which essentially moves the value out of self, temporarily:
        self = nil

        // Make sure to put the modified value back in in the end,
        // no matter what happens during modifications:
        defer {
            self = value
        }

        // Then we try to apply our modifications:
        try modifications(&value)
    }
}
