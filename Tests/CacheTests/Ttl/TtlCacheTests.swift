import XCTest

import CacheKeyGenerators
import PseudoRandom

@testable import Cache

final class TtlCacheTests: XCTestCase {
    typealias Key = Int
    typealias Value = String
    typealias Element = (key: Key, value: Value)
    typealias Cost = Int
    typealias Index = UInt32
    typealias Policy = CapacityPolicy<CustomTtlPolicy<Index>>
    typealias Cache = CustomCache<Key, Value, Policy>

    func cache<Value>(
        minimumCapacity: Int = 0,
        maximumCapacity: Int,
        dateProvider: @escaping () -> Date = Date.init
    ) -> CustomCache<Key, Value, Policy> {
        .init(defaultMetadata: .init()) { minimumCapacity in
            .init(
                base: .init(
                    minimumCapacity: minimumCapacity,
                    dateProvider: dateProvider
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
        let maximumCapacity = 4

        var cache: Cache = self.cache(
            maximumCapacity: maximumCapacity
        )

        cache.setValue("0", forKey: 0, metadata: 1.0)
        cache.setValue("1", forKey: 1, metadata: 2.0)
        cache.setValue("2", forKey: 2, metadata: 3.0)
        cache.setValue("3", forKey: 3, metadata: 1.0)
        cache.setValue("4", forKey: 4, metadata: 2.0)
        cache.setValue("5", forKey: 5, metadata: 3.0)

        XCTAssertEqual(cache.count, maximumCapacity)

        let actual = Dictionary(uniqueKeysWithValues: Array(cache))
        let expected: [Key: Value] = [
            1: "1",
            2: "2",
            4: "4",
            5: "5",
        ]

        XCTAssertEqual(actual, expected)
    }

    func testIsEmpty() throws {
        var cache: Cache = self.cache(
            maximumCapacity: 10
        )

        XCTAssertTrue(cache.isEmpty)

        cache.setValue("0", forKey: 0)

        XCTAssertFalse(cache.isEmpty)
    }

    func testCount() throws {
        var cache: Cache = self.cache(
            maximumCapacity: 10
        )

        XCTAssertEqual(cache.count, 0)

        cache.setValue("0", forKey: 0)
        cache.setValue("1", forKey: 1)
        cache.setValue("2", forKey: 2)

        XCTAssertEqual(cache.count, 3)
    }

    func testRemoveValueForKey() throws {
        var cache: Cache = self.cache(
            maximumCapacity: 10
        )

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
        var cache: Cache = self.cache(
            maximumCapacity: 10
        )

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
        var cache: Cache = self.cache(
            maximumCapacity: 10
        )

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

        var cache: Cache = self.cache(
            maximumCapacity: 10
        )

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
        let referenceDate = Date()
        let dateProvider = DateProvider(date: referenceDate)

        var cache: Cache = self.cache(
            maximumCapacity: 10,
            dateProvider: dateProvider.generateDate
        )

        cache.setValue("0", forKey: 0, metadata: 0.0)
        cache.setValue("1", forKey: 1, metadata: 1.0)
        cache.setValue("2", forKey: 2, metadata: 2.0)

        dateProvider.date = referenceDate.addingTimeInterval(0.5)

        // An existing still-alive key:
        XCTAssertEqual(cache.value(forKey: 2), "2")

        // An existing expired key:
        XCTAssertEqual(cache.value(forKey: 0), nil)

        // A non-existing key:
        XCTAssertEqual(cache.value(forKey: 3), nil)
    }

    func testSimpleScenario() throws {
        let referenceDate = Date()
        let dateProvider = DateProvider(date: referenceDate)

        var cache: Cache = self.cache(
            maximumCapacity: 5,
            dateProvider: dateProvider.generateDate
        )

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
            (3, "_"),
            (4, "4"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key, metadata: 0.0)
        }

        // Access an existing element:
        let _ = cache.value(forKey: 1, metadata: 1.0)

        // Update an existing element:
        let _ = cache.updateValue("3", forKey: 3, metadata: 1.0)

        // Add a new non-existing element:
        let _ = cache.setValue("5", forKey: 5, metadata: 1.0)

        // Add a new non-existing element:
        let _ = cache.setValue("6", forKey: 6, metadata: 1.0)

        // Add a new non-existing element:
        let _ = cache.setValue("7", forKey: 7, metadata: 1.0)

        let actual: [Key: Value] = Dictionary(
            uniqueKeysWithValues: Array(cache)
        )

        let expected: [Key: Value] = [
            1: "1",
            3: "3",
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
    ]
}
