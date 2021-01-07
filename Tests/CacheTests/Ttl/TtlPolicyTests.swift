import XCTest

@testable import Cache

final class TtlPolicyTests: XCTestCase {
    typealias Policy = CustomTtlPolicy<UInt>
    typealias Index = Policy.Index

    func testInit() throws {
        let referenceDate = Date()
        let dateProvider = DateProvider(date: referenceDate)

        let policy = Policy(
            minimumCapacity: 0,
            dateProvider: dateProvider.generateDate
        )

        XCTAssertEqual(policy.count, 0)
        XCTAssertTrue(policy.isEmpty)
        XCTAssertEqual(policy.referenceDate, referenceDate)
        XCTAssertEqual(policy.deadlinesByIndex, [:])
    }

    func testHasCapacity() throws {
        let policy = Policy()

        XCTAssertTrue(policy.hasCapacity(forMetadata: nil))
        XCTAssertTrue(policy.hasCapacity(forMetadata: 1.0))
    }

    func testStateOf() throws {
        var policy = Policy()

        let index = policy.insert(metadata: 1.0)

        XCTAssertEqual(policy.state(of: index), .alive)
    }

    func testInsert() throws {
        let referenceDate = Date()
        let dateProvider = DateProvider(date: referenceDate)

        var policy = Policy(
            minimumCapacity: 0,
            dateProvider: dateProvider.generateDate
        )

        dateProvider.date = referenceDate.addingTimeInterval(0.12345)

        let count = 3

        for i in 0..<count {
            let _ = policy.insert(metadata: .init(i))
        }

        XCTAssertEqual(policy.count, count)
        XCTAssertFalse(policy.isEmpty)

        let expected: [Index: TimeInterval] = [
            .init(0): 0.12345,
            .init(1): 1.12345,
            .init(2): 2.12345,
        ]

        XCTAssertEqual(policy.deadlinesByIndex.keys, expected.keys)

        for (index, expected) in expected {
            let actual = try XCTUnwrap(policy.deadlinesByIndex[index])

            XCTAssertEqual(actual, expected, accuracy: 0.01)
        }
    }

    func testUse() throws {
        var expected: [(Index, TimeInterval, UInt)]
        var expectedIndices: Set<Index>

        let referenceDate = Date()
        let dateProvider = DateProvider(date: referenceDate)

        var policy = Policy(
            minimumCapacity: 0,
            dateProvider: dateProvider.generateDate
        )

        dateProvider.date = referenceDate.addingTimeInterval(0.12345)

        let count = 3

        for i in 0..<count {
            let _ = policy.insert(metadata: .init(i))
        }

        XCTAssertEqual(policy.count, count)
        XCTAssertFalse(policy.isEmpty)

        expected = [
            (.init(0), 0.12345, #line),
            (.init(1), 1.12345, #line),
            (.init(2), 2.12345, #line),
        ]

        expectedIndices = Set(expected.map { $0.0 })

        XCTAssertEqual(
            Set(policy.deadlinesByIndex.keys),
            expectedIndices
        )

        for (index, expected, line) in expected {
            let actual = try XCTUnwrap(
                policy.deadlinesByIndex[index],
                line: line
            )

            XCTAssertEqual(
                actual,
                expected,
                accuracy: 0.01,
                line: line
            )
        }

        dateProvider.date = referenceDate.addingTimeInterval(1.23456)

        let index: Index = .init(1)
        let newIndex = policy.use(index, metadata: 1.0)

        XCTAssertEqual(index, newIndex)

        expected = [
            (.init(0), 0.12345, #line),
            (.init(1), 2.23456, #line),
            (.init(2), 2.12345, #line),
        ]

        expectedIndices = Set(expected.map { $0.0 })

        XCTAssertEqual(
            Set(policy.deadlinesByIndex.keys),
            expectedIndices
        )

        for (index, expected, line) in expected {
            let actual = try XCTUnwrap(
                policy.deadlinesByIndex[index],
                line: line
            )

            XCTAssertEqual(
                actual,
                expected,
                accuracy: 0.01,
                line: line
            )
        }
    }

    func testRemove() throws {
        let referenceDate = Date()
        let dateProvider = DateProvider(date: referenceDate)

        var policy = Policy(
            minimumCapacity: 0,
            dateProvider: dateProvider.generateDate
        )

        dateProvider.date = referenceDate.addingTimeInterval(0.12345)

        let count = 3

        for i in 0..<count {
            let _ = policy.insert(metadata: .init(i))
        }

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index, .init(0))
    }

    func testRemoveIndex() throws {
        var policy = Policy()

        for i in 0..<3 {
            let _ = policy.insert(metadata: .init(i))
        }

        let index: Index = .init(1)

        let _ = policy.remove(index)

        XCTAssertEqual(policy.count, 2)

        XCTAssertNil(policy.deadlinesByIndex[index])
    }

    func testRemoveExpired() throws {
        let referenceDate = Date()
        let dateProvider = DateProvider(date: referenceDate)

        var policy = Policy(
            minimumCapacity: 0,
            dateProvider: dateProvider.generateDate
        )

        for i in 0..<5 {
            let _ = policy.insert(metadata: .init(i))
        }

        dateProvider.date = referenceDate.addingTimeInterval(2.0)

        let expectation = self.expectation(
            description: "Expected expiration"
        )
        expectation.expectedFulfillmentCount = 2

        policy.removeExpired { index in
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 0.0)

        XCTAssertEqual(policy.count, 3)
    }

    func testRemoveAll() throws {
        var policy = Policy()

        for i in 0..<3 {
            let _ = policy.insert(metadata: .init(i))
        }

        policy.removeAll()

        XCTAssertTrue(policy.isEmpty)
        XCTAssertEqual(policy.count, 0)

        XCTAssertEqual(policy.deadlinesByIndex.capacity, 0)
    }

    func testRemoveAllKeepingCapacity() throws {
        var policy = Policy()

        for i in 0..<3 {
            let _ = policy.insert(metadata: .init(i))
        }

        let capacity = policy.deadlinesByIndex.capacity

        policy.removeAll(keepingCapacity: true)

        XCTAssertTrue(policy.isEmpty)
        XCTAssertEqual(policy.count, 0)

        XCTAssertEqual(policy.deadlinesByIndex.capacity, capacity)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInsert", testInsert),
        ("testUse", testUse),
        ("testRemove", testRemove),
        ("testRemoveIndex", testRemoveIndex),
        ("testRemoveAll", testRemoveAll),
        ("testRemoveAllKeepingCapacity", testRemoveAllKeepingCapacity),
    ]
}
