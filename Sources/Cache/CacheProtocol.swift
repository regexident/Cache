// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol CacheProtocol {
    associatedtype Key: Hashable
    associatedtype Value

    var isEmpty: Bool { get }
    var count: Int { get }
    var capacity: Int { get }

    mutating func value(
        forKey key: Key
    ) -> Value?

    func peekValue(
        forKey key: Key
    ) -> Value?

    mutating func setValue(
        _ value: Value?,
        forKey key: Key
    )

    @discardableResult
    mutating func updateValue(
        _ value: Value,
        forKey key: Key
    ) -> Value?
}

public protocol EvictableCacheProtocol: CacheProtocol {
    @discardableResult
    mutating func removeValue(
        forKey key: Key
    ) -> Value?

    mutating func removeAll()

    mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    )
}
