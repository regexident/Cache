import Foundation

import ArgumentParser
import Benchmark

import Cache
import PseudoRandom

typealias BenchmarkPolicyLru = CustomLruPolicy<Int>
typealias BenchmarkPolicyRr = CustomRrPolicy<UInt64, SplitMix64>
typealias BenchmarkPolicyClock = CustomClockPolicy<UInt64>

internal struct RunBenchmarks: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "benchmark",
        abstract: "Convenience command for profiling 'Cache'."
    )

    @Argument(help: "The cache's max capacity")
    internal var capacity: Int = 1000

    @Argument(help: "The number of unique keys to cache")
    internal var keys: Int = 2000

    @Argument(help: "The number of key accesses to perform")
    internal var accesses: Int = 100_000

    @Argument(help: "The order of key accesses to perform")
    internal var orderings: [KeyOrder] = [
        .sequential,
        .semiSequential,
        .randomUniform,
        .randomNormal,
    ]

    mutating func run() throws {
        print("Capacity: \(self.capacity)")
        print("Keys: \(self.keys)")
        print("Accesses: \(self.accesses)")
        print("Orderings: \(self.orderings)")
        print()

        let capacity = self.capacity
        let keyCount = self.keys
        let accessCount = self.accesses

        let suites: [BenchmarkSuite] = self.orderings.map { keyOrder in
            let suite = BenchmarkSuite(name: String(describing: keyOrder))

            let keys = makeKeysFor(
                keys: keyCount,
                accesses: accessCount,
                ordered: keyOrder
            )

            suite.benchmark("lru") {
                runWith(
                    policy: BenchmarkPolicyLru.self,
                    capacity: capacity,
                    keys: keys
                )
            }

            suite.benchmark("rr") {
                runWith(
                    policy: BenchmarkPolicyRr.self,
                    capacity: capacity,
                    keys: keys
                )
            }

            suite.benchmark("clock") {
                runWith(
                    policy: BenchmarkPolicyClock.self,
                    capacity: capacity,
                    keys: keys
                )
            }

            return suite
        }

        Benchmark.main(suites)
    }
}
