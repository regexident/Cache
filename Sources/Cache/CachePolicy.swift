// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol CachePolicy {
    associatedtype Token: Hashable

    init()
    init(minimumCapacity: Int)

    mutating func insert() -> Token

    mutating func use(_ token: Token)

    mutating func remove() -> Token?
    mutating func remove(_ token: Token)
    mutating func removeAll(keepingCapacity keepCapacity: Bool)
}
