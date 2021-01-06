// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import PseudoRandom

// Source: "Quickly Generating Billion-Record Synthetic Databases", Jim Gray et al, SIGMOD 1994
/// A generator that returns values according to a uniform distribution
/// with the "popular" items scattered across the domain.
public struct ScatteredZipfianRandomKeyGenerator<Generator>: IteratorProtocol
where
    Generator: RandomNumberGenerator
{
    public typealias Element = Int

    private let range: Range<Int>
    private var zipfianGenerator: ZipfianRandomKeyGenerator<Generator>

    public init(
        range: Range<Int>,
        theta: Double,
        generator: Generator
    ) {
        self.range = range
        self.zipfianGenerator = .init(
            range: (.min)..<(.max),
            theta: theta,
            generator: generator
        )
    }

    public mutating func next() -> Element? {
        guard let key = self.zipfianGenerator.next() else {
            return nil
        }

        // Scatter by hashing:

        var hasher = Hasher()
        key.hash(into: &hasher)
        let hash = hasher.finalize()

        // Reduce to range by applying modulo:

        let count = self.range.count
        let scatteredKey = self.range.lowerBound + (hash % count)

        return scatteredKey
    }
}
