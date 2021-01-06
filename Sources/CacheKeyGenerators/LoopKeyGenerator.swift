// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// A generator that returns a looping monotonically incrementing bounded sequence of integer values.
public struct LoopKeyGenerator: IteratorProtocol {
    public typealias Element = Int

    public let range: Range<Int>

    private var index: Int = 0

    public mutating func next() -> Element? {
        defer {
            self.index &+= 1
        }

        let index = self.index % self.range.count
        return self.range[index]
    }
}
