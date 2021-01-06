// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import PseudoRandom

/// A generator that returns values resembling a hotspot distribution
/// where sampling is done from hot/cold sets chosen by a specified probability.
/// Elements from the hot/cold sets are chosen using a uniform distribution.
public struct HotspotKeyGenerator {
    public typealias Element = Int

    public let range: Range<Int>
    public let hotCount: Int
    public let hotProbability: Double

    private var prng: SplitMix64

    public init(
        range: Range<Int>,
        hotCount: Int,
        hotProbability: Double,
        prng: SplitMix64
    ) {
        assert(hotCount <= range.count)
        assert(hotProbability >= 0.0)
        assert(hotProbability <= 1.0)

        self.range = range
        self.hotCount = hotCount
        self.hotProbability = hotProbability
        self.prng = prng
    }

    public mutating func next() -> Element? {
        let sample = Double.random(
            in: (0.0)...(1.0),
            using: &self.prng
        )
        let isCold = sample > self.hotProbability
        if isCold {
            let coldRange = self.hotCount..<self.range.count
            return Element.random(in: coldRange, using: &self.prng)
        } else {
            let hotRange = 0..<self.hotCount
            return Element.random(in: hotRange, using: &self.prng)
        }
    }
}
