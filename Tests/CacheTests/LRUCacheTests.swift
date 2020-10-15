import XCTest

@testable import Cache

final class LRUCacheTests: XCTestCase {
    typealias Key = Int
    typealias Value = String
    typealias Element = (key: Key, value: Value)
    typealias Cache = LRUCache<Key, Value>

    func testInit() throws {
        let cache = Cache()

        XCTAssertTrue(cache.isEmpty)
        XCTAssertEqual(cache.count, 0)
    }

    func testInitCapacity() throws {
        let capacity = 3

        var cache = Cache(maximumCount: capacity)

        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
            (3, "3"),
            (4, "4"),
        ]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        XCTAssertEqual(cache.count, capacity)

        let expectedElements = elements.suffix(capacity).reversed()

        for (element, cachedElement) in zip(expectedElements, cache) {
            XCTAssertEqual(element.key, cachedElement.key)
            XCTAssertEqual(element.value, cachedElement.value)
        }
    }

    func testInitUniqueKeysWithValues() throws {
        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
            (3, "3"),
        ]

        let cache = Cache(
            uniqueKeysWithValues: elements
        )

        XCTAssertEqual(cache.count, elements.count)

        let expectedElements = elements.reversed()

        for (element, cachedElement) in zip(expectedElements, cache) {
            XCTAssertEqual(element.key, cachedElement.key)
            XCTAssertEqual(element.value, cachedElement.value)
        }
    }

    func testIsEmpty() throws {
        let emptyCache: Cache = [:]
        XCTAssertTrue(emptyCache.isEmpty)

        let cache: Cache = [
            0: "0",
            1: "1",
            2: "2",
            3: "3",
        ]
        XCTAssertFalse(cache.isEmpty)
    }

    func testCount() throws {
        let emptyCache: Cache = [:]
        XCTAssertEqual(emptyCache.count, 0)

        let cache: Cache = [
            0: "0",
            1: "1",
            2: "2",
            3: "3",
        ]
        XCTAssertEqual(cache.count, 4)
    }

    func testCapacity() throws {
        let elements: [Element] = [
            (0, "0"),
            (1, "1"),
            (2, "2"),
            (3, "3"),
            (4, "4"),
        ]

        var cache: Cache = [:]

        for (key, value) in elements {
            cache.setValue(value, forKey: key)
        }

        let maximumCount = 3

        cache.resizeTo(maximumCount: maximumCount)

        XCTAssertEqual(cache.maximumCount, maximumCount)
        XCTAssertEqual(cache.count, maximumCount)

        let expectedElements = elements.suffix(maximumCount).reversed()

        for (element, cachedElement) in zip(expectedElements, cache) {
            XCTAssertEqual(element.key, cachedElement.key)
            XCTAssertEqual(element.value, cachedElement.value)
        }
    }

    func testRemoveValueForKey() throws {
        var cache: Cache = [
            0: "0",
            1: "1",
            2: "2",
        ]
        XCTAssertEqual(cache.count, 3)

        // Remove non-existing key:
        cache.removeValue(forKey: 42)
        XCTAssertEqual(cache.count, 3)

        // Remove existing key:
        cache.removeValue(forKey: 1)
        XCTAssertEqual(cache.count, 2)
    }

    func testRemoveAll() throws {
        var cache: Cache = [
            0: "0",
            1: "1",
            2: "2",
        ]
        XCTAssertEqual(cache.count, 3)

        cache.removeAll()
        XCTAssertEqual(cache.count, 0)
    }

    func testSetValueForKey() throws {
        var cache: Cache = [
            0: "0",
            1: "1",
            2: "2",
        ]

        // Remove an existing key:
        cache.setValue(nil, forKey: 1)
        XCTAssertEqual(
            cache,
            [
                0: "0",
                2: "2",
            ]
        )

        // The other operations forward to `updateValue(_:forKey:)`
    }

    func testUpdateValueForKey() throws {
        var cache: Cache = [
            0: "0",
            1: "1",
            2: "_",
        ]

        // Add an existing key:
        cache.updateValue("2", forKey: 2)
        XCTAssertEqual(
            cache,
            [
                0: "0",
                1: "1",
                2: "2",
            ]
        )

        // Add non-existing key:
        cache.updateValue("4", forKey: 4)
        XCTAssertEqual(
            cache,
            [
                0: "0",
                1: "1",
                2: "2",
                4: "4",
            ]
        )
    }

    func testValueForKey() throws {
        var cache: Cache = [
            0: "0",
            1: "1",
            2: "2",
        ]

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

        var cache: Cache = [
            0: "0",
            1: "1",
            2: "2",
            3: "_",
            4: "4"
        ]

        cache.resizeTo(maximumCount: 5)

        // Access an existing element:
        let _ = cache.value(forKey: 1)
        // Update an existing element:
        let _ = cache.updateValue("3", forKey: 3)
        // Add a new non-existing element:
        let _ = cache.setValue("5", forKey: 5)

        cache.resizeTo(maximumCount: 4)

        XCTAssertEqual(
            cache,
            [
                1: "1",
                3: "3",
                4: "4",
                5: "5",
            ]
        )
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInitCapacity", testInitCapacity),
        ("testInitUniqueKeysWithValues", testInitUniqueKeysWithValues),
        ("testIsEmpty", testIsEmpty),
        ("testCount", testCount),
        ("testCapacity", testCapacity),
        ("testRemoveValueForKey", testRemoveValueForKey),
        ("testRemoveAll", testRemoveAll),
        ("testSetValueForKey", testSetValueForKey),
        ("testUpdateValueForKey", testUpdateValueForKey),
        ("testValueForKey", testValueForKey),
    ]
}
