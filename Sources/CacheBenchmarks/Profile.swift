import Foundation

import ArgumentParser
import Benchmark

import Cache

internal struct Profile: ParsableCommand {
    static var configuration: CommandConfiguration = .init(
        commandName: "profile",
        abstract: "Convenience command for profiling 'Cache'."
    )

    @Argument(help: "The cache's max capacity")
    internal var capacity: Int = 1000

    @Argument(help: "The number of unique keys to cache")
    internal var keys: Int = 2000

    @Argument(help: "The number of key accesses to perform")
    internal var accesses: Int = 100_000

    @Argument(help: "The ordering of key accesses to perform")
    internal var ordering: KeyOrder = .randomNormal

    @Argument(help: "The cache replacement policy to use")
    internal var policy: CachePolicyKind = .clock

    mutating func run() throws {
        print("Capacity: \(self.capacity)")
        print("Keys: \(self.keys)")
        print("Accesses: \(self.accesses)")
        print("Ordering: \(self.ordering)")
        print()

        let capacity = self.capacity
        let keyCount = self.keys
        let accessCount = self.accesses
        let keyOrder = self.ordering
        let cachePolicy = self.policy

        let keys: [Int] = makeKeysFor(
            keys: keyCount,
            accesses: accessCount,
            ordered: keyOrder
        )

        switch cachePolicy {
        case .lru:
            runWith(
                minimumCapacity: capacity,
                policy: { capacity in BenchmarkPolicyLru(
                    minimumCapacity: capacity
                ) },
                defaultMetadata: BenchmarkPolicyLru.Metadata.default,
                keys: keys
            )
        case .rr:
            runWith(
                minimumCapacity: capacity,
                policy: { capacity in BenchmarkPolicyRr(
                    minimumCapacity: capacity,
                    generator: .init(seed: 42)
                ) },
                defaultMetadata: BenchmarkPolicyRr.Metadata.default,
                keys: keys
            )
        case .clock:
            runWith(
                minimumCapacity: capacity,
                policy: { capacity in BenchmarkPolicyClock(
                    minimumCapacity: capacity
                ) },
                defaultMetadata: BenchmarkPolicyClock.Metadata.default,
                keys: keys
            )
        }
    }
}
