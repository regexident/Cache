import Foundation

import ArgumentParser
import Benchmark

import Cache

internal struct GenerateCharts: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "generate-charts",
        abstract: "Generate benchmark charts for 'Cache'."
    )

    @Argument(help: "The cache's max capacity")
    internal var capacity: Int = 1000

    @Argument(help: "The number of unique keys to cache")
    internal var keys: [Int] = [
        1250, 1500, 1750, 2000, 2250, 2500, 2750, 3000, 4250, 4500, 4750, 5000
    ]

    @Argument(help: "The number of key accesses to perform")
    internal var accesses: Int = 100_000

    @Argument(help: "The ordering of key accesses to perform")
    internal var ordering: KeyOrder = .randomNormal

    mutating func run() throws {
        print("Capacity: \(self.capacity)")
        print("Keys: \(self.keys)")
        print("Accesses: \(self.accesses)")
        print("Ordering: \(self.ordering)")
        print()

        print("Capacity\tKeys\tAccesses\tLRU\tRR\tCLOCK")

        let capacity = self.capacity
        let accessCount = self.accesses
        let keyOrder = self.ordering

        for keyCount in self.keys {
            let keys: [Int] = makeKeysFor(
                keys: keyCount,
                accesses: accessCount,
                ordered: keyOrder
            )

            let lru = measureTime {
                runWith(
                    minimumCapacity: capacity,
                    policy: { capacity in BenchmarkPolicyLru(
                        minimumCapacity: capacity
                    ) },
                    defaultMetadata: BenchmarkPolicyLru.Metadata.default,
                    keys: keys
                )
            }

            let rr = measureTime {
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

            let clock = measureTime {
                runWith(
                    minimumCapacity: capacity,
                    policy: { capacity in BenchmarkPolicyClock(
                        minimumCapacity: capacity
                    ) },
                    defaultMetadata: BenchmarkPolicyClock.Metadata.default,
                    keys: keys
                )
            }

            print("\(capacity)\t\(keyCount)\t\(accessCount)\t\(lru)\t\(rr)\t\(clock)")
        }
    }
}
