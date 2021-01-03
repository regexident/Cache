import XCTest

import Cache
import CacheKeyGenerators

internal typealias Scenario = (
    capacity: Int,
    keys: Int,
    hitRate: Double,
    line: UInt
)

internal func testCacheHitRatio<Keys, Policy>(
    scenarios: [Scenario],
    iterations: Int = 5,
    file: StaticString = #file,
    accesses: (Int, Int) -> Int,
    cache cacheProvider: (Int, Int) -> CustomCache<Int, (), Policy>,
    keys keysProvider: (Int) -> Keys
) throws
where
    Keys: IteratorProtocol,
    Keys.Element == Int,
    Policy: CachePolicy
{
    assert(iterations > 0)
    
    for (capacity, keys, expected, line) in scenarios {
        let actuals: [Double] = try (0..<iterations).map { iteration in
            try calculateCacheHitRatio(
                accesses: accesses(capacity, keys),
                cache: {
                    cacheProvider(capacity, iteration)
                },
                keys: {
                    keysProvider(keys)
                }
            )
        }

        // Median cache hit ratio:
        let actual: Double = actuals.sorted()[actuals.count / 2]

        XCTAssertGreaterThanOrEqual(
            actual,
            expected,
            file: file,
            line: line
        )
    }
}

internal func calculateCacheHitRatio<Keys, Policy>(
    accesses: Int,
    cache cacheProvider: () -> CustomCache<Int, (), Policy>,
    keys keysProvider: () -> Keys
) throws -> Double
where
    Keys: IteratorProtocol,
    Keys.Element == Int,
    Policy: CachePolicy
{
    typealias Key = Int

    let unboundedKeys = keysProvider()
    let boundedKeys = Take(
        from: unboundedKeys,
        count: accesses
    )

    let keys = IteratorSequence(boundedKeys)
    var cache = cacheProvider()

    var keyFrequencies: [Key: Int] = [:]
    var accessedKeys: Set<Key> = []
    var cacheHitsByKey: [Key: Int] = [:]

    for key in keys {
        keyFrequencies[key, default: 0] += 1

        let _ = cache.cachedValue(forKey: key) {
            cacheHitsByKey[key, default: 0] += 1
            return ()
        }

        accessedKeys.insert(key)
    }

    // Subtract `count` to filter out initial compulsory cache misses:
    let cacheHits = cacheHitsByKey.values.reduce(0, +) - cacheHitsByKey.count
    let cacheHitRatio = (1.0 / Double(accesses)) * Double(cacheHits)

    return 1.0 - cacheHitRatio
}
