// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

import PseudoRandom

// Source: "Quickly Generating Billion-Record Synthetic Databases", Jim Gray et al, SIGMOD 1994
/// A generator that returns values according to a uniform distribution.
public struct ZipfianRandomKeyGenerator<Generator>: IteratorProtocol
where
    Generator: RandomNumberGenerator
{
    public typealias Element = Int

    public let range: Range<Element>
    public let alpha: Double
    public let zeta: Double
    public let eta: Double
    public let theta: Double
    public let zeta2theta: Double

    private var generator: Generator

    public init(
        range: Range<Int>,
        theta: Double,
        generator: Generator
    ) {
        let n = range.count

        let zeta = Self.zeta(n: n, theta: theta)
        let zeta2theta = Self.zeta(n: 2, theta: theta)
        let alpha = 1.0 / (1.0 - theta)
        let eta = Self.eta(
            n: n,
            theta: theta,
            zeta: zeta,
            zeta2theta: zeta2theta
        )

        self.init(
            range: range,
            alpha: alpha,
            zeta: zeta,
            eta: eta,
            theta: theta,
            zeta2theta: zeta2theta,
            generator: generator
        )
    }

    private init(
        range: Range<Element>,
        alpha: Double,
        zeta: Double,
        eta: Double,
        theta: Double,
        zeta2theta: Double,
        generator: Generator
    ) {
        self.range = range
        self.theta = theta
        self.zeta = zeta
        self.zeta2theta = zeta2theta
        self.alpha = alpha
        self.eta = eta

        self.generator = generator
    }

    private static func zeta(
        n: Int,
        theta: Double
    ) -> Double {
        var sum: Double = 0.0

        for i in 1...n {
            sum += 1.0 / pow(Double(i), theta)
        }

        return sum
    }

    private static func eta(
        n: Int,
        theta: Double,
        zeta: Double,
        zeta2theta: Double
    ) -> Double {
        let numerator = 1.0 - pow(2.0 / Double(n), 1 - theta)
        let denominator = 1.0 - zeta2theta / zeta
        return numerator / denominator
    }

    public mutating func next() -> Element? {
        let u = Double.random(
            in: (0.0)...(1.0),
            using: &self.generator
        )
        let uz = u * self.zeta

        let min = self.range.lowerBound
        let n = self.range.count

        if uz < 1.0 {
            return min
        }

        if uz < 1.0 + pow(0.5, self.theta) {
            return min + 1
        }

        let key = min + Int(Double(n) * pow(self.eta * u - self.eta + 1.0, self.alpha))

        return key
    }
}
