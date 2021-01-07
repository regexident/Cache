import XCTest

import CacheKeyGenerators
import PseudoRandom

@testable import Cache

final class FifoCacheTests: XCTestCase {
    typealias Key = Int
    typealias Value = String
    typealias Element = (key: Key, value: Value)
    typealias Cost = Int
    typealias Index = UInt32
    typealias Policy = CapacityPolicy<CustomFifoPolicy<Index>>
    typealias Cache = CustomCache<Key, Value, Policy>

    func cache<Value>(
        minimumCapacity: Int = 0,
        maximumCapacity: Int
    ) -> CustomCache<Key, Value, Policy> {
        .init(defaultMetadata: .init()) { minimumCapacity in
            .init(
                base: .init(
                    minimumCapacity: minimumCapacity
                ),
                maximumCapacity: maximumCapacity
            )
        }
    }

    func testInit() throws {
        let cache: Cache = self.cache(maximumCapacity: 10)

        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)
    }

    func testMaximumCapacity() throws {
        let maximumCapacity = 3

        var cache: Cache = self.cache(maximumCapacity: maximumCapacity)

        cache.setValue("0", forKey: 0)
        cache.setValue("1", forKey: 1)
        cache.setValue("2", forKey: 2)
        cache.setValue("3", forKey: 3)
        cache.setValue("4", forKey: 4)
        cache.setValue("5", forKey: 5)

        XCTAssertEqual(cache.count, maximumCapacity)

        let actual = Dictionary(uniqueKeysWithValues: Array(cache))
        let expected: [Key: Value] = [
            3: "3",
            4: "4",
            5: "5",
        ]

        XCTAssertEqual(actual, expected)
    }

    func testIsEmpty() throws {
        var cache: Cache = self.cache(maximumCapacity: 10)

        XCTAssertTrue(cache.isEmpty)

        cache.setValue("0", forKey: 0)

        XCTAssertFalse(cache.isEmpty)
    }

    func testCount() throws {
        var cache: Cache = self.cache(maximumCapacity: 10)

        XCTAssertEqual(cache.count, 0)

        cache.setValue("0", forKey: 0)
        cache.setValue("1", forKey: 1)
        cache.setValue("2", forKey: 2)

        XCTAssertEqual(cache.count, 3)
    }

    func testRemoveValueForKey() throws {
        var cache: Cache = self.cache(maximumCapacity: 10)

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        XCTAssertEqual(cache.count, 3)

        // Remove non-existing key:
        cache.removeValue(forKey: 42)
        XCTAssertEqual(cache.count, 3)

        // Remove existing key:
        cache.removeValue(forKey: 1)
        XCTAssertEqual(cache.count, 2)
    }

    func testRemoveAll() throws {
        var cache: Cache = self.cache(maximumCapacity: 10)

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        XCTAssertEqual(cache.count, 3)

        cache.removeAll()
        XCTAssertEqual(cache.count, 0)
    }

    func testSetValueForKey() throws {
        var cache: Cache = self.cache(maximumCapacity: 10)

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        // Remove an existing key:
        cache.setValue(nil, forKey: 1)

        let actual: [Key: Value] = Dictionary(
            uniqueKeysWithValues: Array(cache)
        )

        let expected: [Key: Value] = [
            0: "0",
            2: "2",
        ]

        XCTAssertEqual(actual, expected)
    }

    func testUpdateValueForKey() throws {
        var actual: [Key: Value]
        var expected: [Key: Value]

        var cache: Cache = self.cache(maximumCapacity: 10)

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "_"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        // Add an existing key:
        cache.updateValue("2", forKey: 2)

        actual = Dictionary(
            uniqueKeysWithValues: Array(cache)
        )

        expected = [
            0: "0",
            1: "1",
            2: "2",
        ]

        XCTAssertEqual(actual, expected)

        // Add non-existing key:
        cache.updateValue("4", forKey: 4)

        actual = Dictionary(
            uniqueKeysWithValues: Array(cache)
        )

        expected = [
            0: "0",
            1: "1",
            2: "2",
            4: "4",
        ]

        XCTAssertEqual(actual, expected)
    }

    func testValueForKey() throws {
        var cache: Cache = self.cache(maximumCapacity: 10)

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        // An existing key:
        XCTAssertEqual(cache.value(forKey: 2), "2")

        // A non-existing key:
        XCTAssertEqual(cache.value(forKey: 3), nil)
    }

    func testSimpleScenario() throws {
        var cache: Cache = self.cache(maximumCapacity: 5)

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
            (3, "_"),
            (4, "4"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        // Access an existing element:
        let _ = cache.value(forKey: 1)

        // Update an existing element:
        let _ = cache.updateValue("3", forKey: 3)

        // Add a new non-existing element:
        let _ = cache.setValue("5", forKey: 5)

        // Add a new non-existing element:
        let _ = cache.setValue("6", forKey: 6)

        // Add a new non-existing element:
        let _ = cache.setValue("7", forKey: 7)

        let actual: [Key: Value] = Dictionary(
            uniqueKeysWithValues: Array(cache)
        )

        let expected: [Key: Value] = [
            3: "3",
            4: "4",
            5: "5",
            6: "6",
            7: "7",
        ]

        XCTAssertEqual(actual, expected)
    }

    func testSmoke() throws {
        shouldValidate = true
        defer {
            shouldValidate = false
        }
        
        let maximumCapacity: Int = 10
        let keyCount: Int = 100
        let accessCount: Int = 1000

        let keys: Range<Int> = 0..<keyCount

        var cache: Cache = self.cache(maximumCapacity: maximumCapacity)

        for i in 0..<accessCount {
            let index = i % Int(Double(maximumCapacity) * 1.1)
            let key = keys[index]
            let _ = cache.cachedValue(forKey: key) {
                String(describing: key)
            }
        }
    }

    // MARK: - Access Patterns

    func testRepeatingKeyAccess() throws {
        try testCacheHitRatio(
            scenarios: [
                (capacity: 100, keys:  50, hitRate: 1.00, line: #line),
                (capacity: 100, keys: 125, hitRate: 1.00, line: #line),
                (capacity: 100, keys: 150, hitRate: 1.00, line: #line),
                (capacity: 100, keys: 200, hitRate: 1.00, line: #line),
            ],
            iterations: 1,
            accesses: { capacity, keys in
                10 * capacity
            },
            cache: { maximumCapacity, iteration in
                self.cache(maximumCapacity: maximumCapacity)
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
            scenarios: [
                (capacity: 100, keys:  50, hitRate: 1.00, line: #line),
                (capacity: 100, keys: 125, hitRate: 0.00, line: #line),
                (capacity: 100, keys: 150, hitRate: 0.00, line: #line),
                (capacity: 100, keys: 200, hitRate: 0.00, line: #line),
            ],
            iterations: 1,
            accesses: { capacity, keys in
                10 * capacity
            },
            cache: { maximumCapacity, _ in
                self.cache(maximumCapacity: maximumCapacity)
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
            scenarios: [
                (capacity: 100, keys:  50, hitRate: 1.00, line: #line),
                (capacity: 100, keys: 125, hitRate: 0.79, line: #line),
                (capacity: 100, keys: 150, hitRate: 0.66, line: #line),
                (capacity: 100, keys: 200, hitRate: 0.49, line: #line),
            ],
            iterations: 1,
            accesses: { capacity, keys in
                10 * capacity
            },
            cache: { maximumCapacity, _ in
                self.cache(maximumCapacity: maximumCapacity)
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
            scenarios: [
                (capacity: 100, keys:  50, hitRate: 1.00, line: #line),
                (capacity: 100, keys: 125, hitRate: 0.94, line: #line),
                (capacity: 100, keys: 150, hitRate: 0.90, line: #line),
                (capacity: 100, keys: 200, hitRate: 0.83, line: #line),
            ],
            iterations: 1,
            accesses: { capacity, keys in
                10 * capacity
            },
            cache: { maximumCapacity, _ in
                self.cache(maximumCapacity: maximumCapacity)
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
        ("testMaximumCapacity", testMaximumCapacity),
        ("testIsEmpty", testIsEmpty),
        ("testCount", testCount),
        ("testRemoveValueForKey", testRemoveValueForKey),
        ("testRemoveAll", testRemoveAll),
        ("testSetValueForKey", testSetValueForKey),
        ("testUpdateValueForKey", testUpdateValueForKey),
        ("testValueForKey", testValueForKey),
        ("testSimpleScenario", testSimpleScenario),
        ("testSmoke", testSmoke),
        ("testRepeatingKeyAccess", testRepeatingKeyAccess),
        ("testRepeatingRangeAccess", testRepeatingRangeAccess),
        ("testUniformRandomAccess", testUniformRandomAccess),
        ("testZipfianRandomAccess", testZipfianRandomAccess),
    ]
}
