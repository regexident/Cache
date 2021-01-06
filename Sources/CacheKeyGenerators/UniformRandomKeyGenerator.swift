// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import PseudoRandom

/// A generator that returns values according to a uniform distribution.
public struct UniformRandomKeyGenerator<Generator>: IteratorProtocol
where
    Generator: RandomNumberGenerator
{
    public typealias Element = Int

    public let range: Range<Element>

    private var generator: Generator

    public init(
        range: Range<Element>,
        generator: Generator
    ) {
        self.range = range
        self.generator = generator
    }

    public mutating func next() -> Element? {
        self.range.randomElement(using: &self.generator)
    }
}
