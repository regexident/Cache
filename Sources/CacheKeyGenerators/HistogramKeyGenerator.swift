// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import PseudoRandom

/// A generator that returns values according to a provided histogram distribution.
public struct HistogramKeyGenerator<Generator>: IteratorProtocol
where
    Generator: RandomNumberGenerator
{
    public typealias Element = Int

    public let histogram: [Element: Double]

    private let area: Double
    private var generator: Generator

    public init(
        histogram: [Element: Double],
        generator: Generator
    ) {
        assert(histogram.values.allSatisfy { $0 > 0.0 })

        self.histogram = histogram
        self.area = histogram.values.reduce(0.0, +)
        self.generator = generator
    }

    public mutating func next() -> Element? {
        let sampleWeight = Double.random(
            in: (0.0)...(1.0),
            using: &self.generator
        )
        var weightSum: Double = 0.0
        for (key, weight) in self.histogram {
            if weightSum >= sampleWeight {
                return key
            }
            weightSum += weight
        }
        return nil
    }
}
