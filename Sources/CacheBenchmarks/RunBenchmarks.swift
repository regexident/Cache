import Foundation

import ArgumentParser
import Benchmark

import Cache
import PseudoRandom

typealias BenchmarkPolicyLru = CustomLruPolicy<UInt64>
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
                    minimumCapacity: capacity,
                    policy: { capacity in BenchmarkPolicyLru(
                        minimumCapacity: capacity
                    ) },
                    defaultMetadata: BenchmarkPolicyLru.Metadata.default,
                    keys: keys
                )
            }

            suite.benchmark("rr") {
                runWith(
                    minimumCapacity: capacity,
                    policy: { capacity in BenchmarkPolicyRr(
                        minimumCapacity: capacity,
                        generator: .init(seed: 42)
                    ) },
                    defaultMetadata: BenchmarkPolicyRr.Metadata.default,
                    keys: keys
                )
            }

            suite.benchmark("clock") {
                runWith(
                    minimumCapacity: capacity,
                    policy: { capacity in BenchmarkPolicyClock(
                        minimumCapacity: capacity
                    ) },
                    defaultMetadata: BenchmarkPolicyClock.Metadata.default,
                    keys: keys
                )
            }

            return suite
        }

        Benchmark.main(suites)
    }
}
