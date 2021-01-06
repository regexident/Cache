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
    accesses: Int,
    scenarios: [Scenario],
    file: StaticString = #file,
    cache cacheProvider: (Int) -> CustomCache<Int, (), Int, Policy>,
    keys keysProvider: (Int) -> Keys
) throws
where
    Keys: IteratorProtocol,
    Keys.Element == Int,
    Policy: CachePolicy
{
    for (capacity, keys, expected, line) in scenarios {
        let actual = try calculateCacheHitRatio(
            accesses: accesses,
            cache: {
                cacheProvider(capacity)
            },
            keys: {
                keysProvider(keys)
            }
        )

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
    cache cacheProvider: () -> CustomCache<Int, (), Int, Policy>,
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
