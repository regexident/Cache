import XCTest

@testable import Cache

final class ClockCacheTests: XCTestCase {
    typealias Key = Int
    typealias Value = String
    typealias Element = (key: Key, value: Value)
    typealias Cost = Int
    typealias Bits = UInt8
    typealias Policy = CustomClockPolicy<Bits>
    typealias Cache = CustomCache<Key, Value, Cost, Policy>

    func cache(
        totalCostLimit: Cost? = nil,
        defaultCost: Cost = 1,
        elements: [Element] = []
    ) -> Cache {
        var cache = Cache(
            totalCostLimit: totalCostLimit,
            defaultCost: defaultCost
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
    ]
}
