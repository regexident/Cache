import XCTest

@testable import Cache

final class ClockPolicyTests: XCTestCase {
    typealias Bits = UInt8
    typealias Policy = CustomClockPolicy<Bits>
    typealias Index = Policy.Index

    func policy(
        count: Int = 0
    ) -> Policy {
        var policy = Policy()

        for _ in 0..<count {
            let _ = policy.insert()
        }

        return policy
    }

    func testInit() throws {
        let policy = self.policy()

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [])
        XCTAssertEqual(policy.referencedBits, [])
    }

    func testInsertIntoEmptyPolicy() throws {
        var policy = self.policy()

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 0)
        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.occupiedBits, [0b00000001])
        XCTAssertEqual(policy.referencedBits, [0b00000001])
        XCTAssertEqual(policy.cursors.insert, 1)
        XCTAssertEqual(policy.cursors.remove, 0)
    }

    func testInsertIntoDenselyFilledPolicy() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00000111])
        XCTAssertEqual(policy.referencedBits, [0b00000111])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 0)

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.occupiedBits, [0b00001111])
        XCTAssertEqual(policy.referencedBits, [0b00001111])
        XCTAssertEqual(policy.cursors.insert, 4)
        XCTAssertEqual(policy.cursors.remove, 0)
    }

    func testInsertIntoSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011001],
            referencedBits: [0b00011001],
            insertCursor: 3,
            removeCursor: 3
        )

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 5)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.occupiedBits, [0b00111001])
        XCTAssertEqual(policy.referencedBits, [0b00111001])
        XCTAssertEqual(policy.cursors.insert, 6)
        XCTAssertEqual(policy.cursors.remove, 3)
    }

    func testInsertIntoSaturatedPolicy() {
        var policy = Policy(
            count: 8,
            occupiedBits: [0b11111111],
            referencedBits: [0b11111111],
            insertCursor: 3,
            removeCursor: 3
        )

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 8)
        XCTAssertEqual(policy.count, 9)
        XCTAssertEqual(policy.occupiedBits, [0b11111111, 0b00000001])
        XCTAssertEqual(policy.referencedBits, [0b11111111, 0b00000001])
        XCTAssertEqual(policy.cursors.insert, 9)
        XCTAssertEqual(policy.cursors.remove, 3)
    }

    func testUse() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011010],
            referencedBits: [0b00010010],
            insertCursor: 3,
            removeCursor: 3
        )

        // Use referenced index:

        policy.use(.init(absoluteBitIndex: 3))

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00011010])
        XCTAssertEqual(policy.referencedBits, [0b00011010])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 3)

        // Use unreferenced index:

        policy.use(.init(absoluteBitIndex: 3))

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00011010])
        XCTAssertEqual(policy.referencedBits, [0b00011010])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 3)
    }

    func testRemoveFromFullPolicy() throws {
        var policy = Policy(
            count: 8,
            occupiedBits: [0b11111111],
            referencedBits: [0b11111111],
            insertCursor: 3,
            removeCursor: 3
        )

        let index = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 7)
        XCTAssertEqual(policy.occupiedBits, [0b11110111])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 4)
    }

    func testRemoveFromDenselyFilledPolicy() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00000111])
        XCTAssertEqual(policy.referencedBits, [0b00000111])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 0)

        let index = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 0)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.occupiedBits, [0b00000110])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 1)
    }

    func testRemoveFromSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011010],
            referencedBits: [0b00011010],
            insertCursor: 3,
            removeCursor: 3
        )

        let index = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.occupiedBits, [0b00010010])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 4)
    }

    func testRemoveIndex() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011010],
            referencedBits: [0b00011010],
            insertCursor: 3,
            removeCursor: 3
        )

        policy.remove(.init(absoluteBitIndex: 1))

        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.occupiedBits, [0b00011000])
        XCTAssertEqual(policy.referencedBits, [0b00011000])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 3)

        policy.remove(.init(absoluteBitIndex: 4))

        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.occupiedBits, [0b00001000])
        XCTAssertEqual(policy.referencedBits, [0b00001000])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 3)

        policy.remove(.init(absoluteBitIndex: 3))

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [0b00000000])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, 3)
        XCTAssertEqual(policy.cursors.remove, 3)
    }

    func testRemoveAll() throws {
        var policy = self.policy(count: 3)

        policy.removeAll()

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [])
        XCTAssertEqual(policy.referencedBits, [])
        XCTAssertEqual(policy.cursors.insert, 0)
        XCTAssertEqual(policy.cursors.remove, 0)
        XCTAssertEqual(policy.capacity, 0)
    }

    func testRemoveAllKeepingCapacity() throws {
        var policy = self.policy(count: 3)

        let capacity = policy.capacity

        policy.removeAll(keepingCapacity: true)

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [])
        XCTAssertEqual(policy.referencedBits, [])
        XCTAssertEqual(policy.cursors.insert, 0)
        XCTAssertEqual(policy.cursors.remove, 0)
        XCTAssertEqual(policy.capacity, capacity)
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInsertIntoEmptyPolicy", testInsertIntoEmptyPolicy),
        ("testInsertIntoDenselyFilledPolicy", testInsertIntoDenselyFilledPolicy),
        ("testInsertIntoSparselyFilledPolicy", testInsertIntoSparselyFilledPolicy),
        ("testInsertIntoSaturatedPolicy", testInsertIntoSaturatedPolicy),
        ("testUse", testUse),
        ("testRemoveFromFullPolicy", testRemoveFromFullPolicy),
        ("testRemoveFromDenselyFilledPolicy", testRemoveFromDenselyFilledPolicy),
        ("testRemoveFromSparselyFilledPolicy", testRemoveFromSparselyFilledPolicy),
        ("testRemoveIndex", testRemoveIndex),
        ("testRemoveAll", testRemoveAll),
        ("testRemoveAllKeepingCapacity", testRemoveAllKeepingCapacity),
    ]
}
