// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import PseudoRandom

/// A generator that returns values according to a uniform distribution.
public struct UniformKeyGenerator: IteratorProtocol {
    public typealias Element = Int

    public let range: Range<Element>

    private var prng: SplitMix64

    public init(
        range: Range<Element>,
        prng: SplitMix64
    ) {
        self.range = range
        self.prng = prng
    }

    public mutating func next() -> Element? {
        self.range.randomElement(using: &self.prng)
    }
}
