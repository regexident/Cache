import XCTest

import CacheKeyGenerators
import PseudoRandom

@testable import Cache

final class LruCacheTests: XCTestCase {
    typealias Key = Int
    typealias Value = String
    typealias Element = (key: Key, value: Value)
    typealias Cost = Int
    typealias Index = UInt32
    typealias Policy = CustomLruPolicy<Index>
    typealias Cache = CustomCache<Key, Value, Cost, Policy>

    let accesses: Int = 100_000

    func cache(
        minimumCapacity: Int? = nil,
        totalCostLimit: Cost? = nil,
        defaultCost: Cost = 1,
        elements: [Element] = []
    ) -> Cache {
        var cache = Cache(
            totalCostLimit: totalCostLimit,
            defaultCost: 1,
            policy: { minimumCapacity in
                LruPolicy(minimumCapacity: minimumCapacity)
            }
        )

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        return cache
    }

    func testInit() throws {
        let cache = self.cache()

        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)
    }

    func testTotalCostLimit() throws {
        let totalCostLimit = 10

        var cache = self.cache(
            totalCostLimit: totalCostLimit
        )

        cache.setValue("0", forKey: 0, cost: 0)
        cache.setValue("1", forKey: 1, cost: 1)
        cache.setValue("2", forKey: 2, cost: 2)
        cache.setValue("3", forKey: 3, cost: 3)
        cache.setValue("4", forKey: 4, cost: 4)
        cache.setValue("5", forKey: 5, cost: 5)

        XCTAssertEqual(cache.totalCost, 9)
        XCTAssertEqual(cache.count, 2)

        let actual = Dictionary(uniqueKeysWithValues: Array(cache))
        let expected: [Key: Value] = [
            4: "4",
            5: "5",
        ]

        XCTAssertEqual(actual, expected)
    }

    func testIsEmpty() throws {
        var cache = Cache()

        XCTAssertTrue(cache.isEmpty)

        cache.setValue("0", forKey: 0)

        XCTAssertFalse(cache.isEmpty)
    }

    func testCount() throws {
        var cache = Cache()

        XCTAssertEqual(cache.count, 0)

        cache.setValue("0", forKey: 0)
        cache.setValue("1", forKey: 1)
        cache.setValue("2", forKey: 2)

        XCTAssertEqual(cache.count, 3)
    }

    func testRemoveValueForKey() throws {
        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
        ]

        var cache = self.cache(
            elements: elements
        )

        XCTAssertEqual(cache.count, 3)

        // Remove non-existing key:
        cache.removeValue(forKey: 42)
        XCTAssertEqual(cache.count, 3)

        // Remove existing key:
        cache.removeValue(forKey: 1)
        XCTAssertEqual(cache.count, 2)
    }

    func testRemoveAll() throws {
        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
        ]

        var cache = self.cache(
            elements: elements
        )

        XCTAssertEqual(cache.count, 3)

        cache.removeAll()
        XCTAssertEqual(cache.count, 0)
    }

    func testSetValueForKey() throws {
        var cache = self.cache(
            elements: [
                (0, "0"),
                (1, "1"),
                (2, "2"),
            ]
        )

        // Remove an existing key:
        cache.setValue(nil, forKey: 1)
        XCTAssertEqual(
            cache,
            self.cache(
                elements: [
                    (0, "0"),
                    (2, "2"),
                ]
            )
        )

        // The other operations forward to `updateValue(_:forKey:)`
    }

    func testUpdateValueForKey() throws {
        var cache = self.cache(
            elements: [
                (0, "0"),
                (1, "1"),
                (2, "_"),
            ]
        )

        // Add an existing key:
        cache.updateValue("2", forKey: 2)
        XCTAssertEqual(
            cache,
            self.cache(
                elements: [
                    (0, "0"),
                    (1, "1"),
                    (2, "2"),
                ]
            )
        )

        // Add non-existing key:
        cache.updateValue("4", forKey: 4)
        XCTAssertEqual(
            cache,
            self.cache(
                elements: [
                    (0, "0"),
                    (1, "1"),
                    (2, "2"),
                    (4, "4"),
                ]
            )
        )
    }

    func testValueForKey() throws {
        var cache = self.cache(
            elements: [
                (0, "0"),
                (1, "1"),
                (2, "2"),
            ]
        )

        // An existing key:
        XCTAssertEqual(cache.value(forKey: 2), "2")

        // A non-existing key:
        XCTAssertEqual(cache.value(forKey: 3), nil)
    }

    func testAccessImpliesUse() throws {
        // The array literal initializer adds (i.e. uses)
        // elements in their order of appearance within the code.
        // As such `(0: "0")` is the least-recently used element,
        // while `(4: "4")` is the most-recently used element:

        var cache = self.cache(
            totalCostLimit: 5,
            elements: [
                (0, "0"),
                (1, "1"),
                (2, "2"),
                (3, "_"),
                (4, "4"),
            ]
        )

        // Access an existing element:
        let _ = cache.value(forKey: 1)
        // Update an existing element:
        let _ = cache.updateValue("3", forKey: 3)
        // Add a new non-existing element:
        let _ = cache.setValue("5", forKey: 5)

        cache.totalCostLimit = 4

        XCTAssertEqual(
            cache,
            self.cache(
                elements: [
                    (1, "1"),
                    (3, "3"),
                    (4, "4"),
                    (5, "5"),
                ]
            )
        )
    }

    func testSmoke() throws {
        shouldValidate = true
        defer {
            shouldValidate = false
        }
        
        let capacity: Int = 10
        let keyCount: Int = 100
        let accessCount: Int = 1000

        let keys: Range<Int> = 0..<keyCount

        var cache = Cache(totalCostLimit: capacity)

        for i in 0..<accessCount {
            let index = i % Int(Double(capacity) * 1.1)
            let key = keys[index]
            let _ = cache.cachedValue(forKey: key) {
                String(describing: key)
            }
        }
    }

    // MARK: - Access Patterns

    func testRepeatingKeyAccess() throws {
        try testCacheHitRatio(
            accesses: self.accesses,
            scenarios: [
                (capacity: 1000, keys: 500, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 1250, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 1500, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 2000, hitRate: 1.0, line: #line),
            ],
            cache: { capacity in
                LruCache(totalCostLimit: capacity)
            },
            keys: { _ in
                RepeatingKeyGenerator(
                    key: 0
                )
            }
        )
    }

    func testRepeatingRangeAccess() throws {
        try testCacheHitRatio(
            accesses: self.accesses,
            scenarios: [
                (capacity: 1000, keys: 500, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 1250, hitRate: 0.013, line: #line),
                (capacity: 1000, keys: 1500, hitRate: 0.015, line: #line),
                (capacity: 1000, keys: 2000, hitRate: 0.02, line: #line),
            ],
            cache: { capacity in
                LruCache(totalCostLimit: capacity)
            },
            keys: { keys in
                RepeatingRangeKeyGenerator(
                    range: 0..<keys
                )
            }
        )
    }

    func testUniformRandomAccess() throws {
        try testCacheHitRatio(
            accesses: self.accesses,
            scenarios: [
                (capacity: 1000, keys: 500, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 1250, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 1500, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 2000, hitRate: 1.0, line: #line),
            ],
            cache: { capacity in
                LruCache(totalCostLimit: capacity)
            },
            keys: { keys in
                UniformRandomKeyGenerator(
                    range: 0..<keys,
                    generator: SplitMix64()
                )
            }
        )
    }

    func testZipfianRandomAccess() throws {
        try testCacheHitRatio(
            accesses: self.accesses,
            scenarios: [
                (capacity: 1000, keys: 500, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 1250, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 1500, hitRate: 1.0, line: #line),
                (capacity: 1000, keys: 2000, hitRate: 1.0, line: #line),
            ],
            cache: { capacity in
                LruCache(totalCostLimit: capacity)
            },
            keys: { keys in
                ZipfianRandomKeyGenerator(
                    range: 0..<keys,
                    theta: 0.99,
                    generator: SplitMix64()
                )
            }
        )
    }

    static var allTests = [
        ("testInit", testInit),
        ("testTotalCostLimit", testTotalCostLimit),
        ("testIsEmpty", testIsEmpty),
        ("testCount", testCount),
        ("testRemoveValueForKey", testRemoveValueForKey),
        ("testRemoveAll", testRemoveAll),
        ("testSetValueForKey", testSetValueForKey),
        ("testUpdateValueForKey", testUpdateValueForKey),
        ("testValueForKey", testValueForKey),
        ("testAccessImpliesUse", testAccessImpliesUse),
        ("testSmoke", testSmoke),
        ("testRepeatingKeyAccess", testRepeatingKeyAccess),
        ("testRepeatingRangeAccess", testRepeatingRangeAccess),
        ("testUniformRandomAccess", testUniformRandomAccess),
        ("testZipfianRandomAccess", testZipfianRandomAccess),
    ]
}
