// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// A generator that returns a monotonically incrementing sequence of integer values.
public struct CounterKeyGenerator: IteratorProtocol {
    public typealias Element = Int

    public private(set) var currentKey: Element

    public mutating func next() -> Element? {
        defer {
            self.currentKey &+= 1
        }

        return self.currentKey
    }
}
