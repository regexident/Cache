// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// A generator that always returns the same integer value.
public struct ConstantKeyGenerator: IteratorProtocol {
    public typealias Element = Int

    public let key: Element

    public func next() -> Element? {
        self.key
    }
}
