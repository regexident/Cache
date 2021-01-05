import XCTest

@testable import Cache

final class ClockPolicyTests: XCTestCase {
    typealias Bits = UInt8
    typealias Policy = CustomClockPolicy<Bits>
    typealias Index = Policy.Index

    func testInit() throws {
        let policy = Policy()

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [])
        XCTAssertEqual(policy.referencedBits, [])
    }

    func testInsertIntoEmptyPolicy() throws {
        var policy = Policy()

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 0)
        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.occupiedBits, [0b00000001])
        XCTAssertEqual(policy.referencedBits, [0b00000001])
        XCTAssertEqual(policy.cursors.insert, .init(1))
        XCTAssertEqual(policy.cursors.remove, .init(0))
    }

    func testInsertIntoDenselyFilledPolicy() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(payload: .default)
        }

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00000111])
        XCTAssertEqual(policy.referencedBits, [0b00000111])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(0))

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.occupiedBits, [0b00001111])
        XCTAssertEqual(policy.referencedBits, [0b00001111])
        XCTAssertEqual(policy.cursors.insert, .init(4))
        XCTAssertEqual(policy.cursors.remove, .init(0))
    }

    func testInsertIntoSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011001],
            referencedBits: [0b00011001],
            insertCursor: .init(3),
            removeCursor: .init(3)
        )

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 5)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.occupiedBits, [0b00111001])
        XCTAssertEqual(policy.referencedBits, [0b00111001])
        XCTAssertEqual(policy.cursors.insert, .init(6))
        XCTAssertEqual(policy.cursors.remove, .init(3))
    }

    func testInsertIntoSaturatedPolicy() {
        var policy = Policy(
            count: 8,
            occupiedBits: [0b11111111],
            referencedBits: [0b11111111],
            insertCursor: .init(3),
            removeCursor: .init(3)
        )

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 8)
        XCTAssertEqual(policy.count, 9)
        XCTAssertEqual(policy.occupiedBits, [0b11111111, 0b00000001])
        XCTAssertEqual(policy.referencedBits, [0b11111111, 0b00000001])
        XCTAssertEqual(policy.cursors.insert, .init(9))
        XCTAssertEqual(policy.cursors.remove, .init(3))
    }

    func testUse() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011010],
            referencedBits: [0b00010010],
            insertCursor: .init(3),
            removeCursor: .init(3)
        )

        var index: Index

        // Use referenced index:

        index = policy.use(.init(3), payload: .default)

        XCTAssertEqual(index, .init(3))

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00011010])
        XCTAssertEqual(policy.referencedBits, [0b00011010])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(3))

        // Use unreferenced index:

        index = policy.use(.init(3), payload: .default)

        XCTAssertEqual(index, .init(3))

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00011010])
        XCTAssertEqual(policy.referencedBits, [0b00011010])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(3))
    }

    func testRemoveFromFullPolicy() throws {
        var policy = Policy(
            count: 8,
            occupiedBits: [0b11111111],
            referencedBits: [0b11111111],
            insertCursor: .init(3),
            removeCursor: .init(3)
        )

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 7)
        XCTAssertEqual(policy.occupiedBits, [0b11110111])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(4))
    }

    func testRemoveFromDenselyFilledPolicy() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(payload: .default)
        }

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.occupiedBits, [0b00000111])
        XCTAssertEqual(policy.referencedBits, [0b00000111])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(0))

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 0)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.occupiedBits, [0b00000110])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(1))
    }

    func testRemoveFromSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011010],
            referencedBits: [0b00011010],
            insertCursor: .init(3),
            removeCursor: .init(3)
        )

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.occupiedBits, [0b00010010])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(4))
    }

    func testRemoveIndex() throws {
        var policy = Policy(
            count: 3,
            occupiedBits: [0b00011010],
            referencedBits: [0b00011010],
            insertCursor: .init(3),
            removeCursor: .init(3)
        )

        let _ = policy.remove(.init(1))

        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.occupiedBits, [0b00011000])
        XCTAssertEqual(policy.referencedBits, [0b00011000])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(3))

        let _ = policy.remove(.init(4))

        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.occupiedBits, [0b00001000])
        XCTAssertEqual(policy.referencedBits, [0b00001000])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(3))

        let _ = policy.remove(.init(3))

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [0b00000000])
        XCTAssertEqual(policy.referencedBits, [0b00000000])
        XCTAssertEqual(policy.cursors.insert, .init(3))
        XCTAssertEqual(policy.cursors.remove, .init(3))
    }

    func testRemoveAll() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(payload: .default)
        }

        policy.removeAll()

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [])
        XCTAssertEqual(policy.referencedBits, [])
        XCTAssertEqual(policy.cursors.insert, .init(0))
        XCTAssertEqual(policy.cursors.remove, .init(0))
        XCTAssertEqual(policy.capacity, 0)
    }

    func testRemoveAllKeepingCapacity() throws {
        var policy = Policy()

        for _ in 0..<3 {
            let _ = policy.insert(payload: .default)
        }

        let capacity = policy.capacity

        policy.removeAll(keepingCapacity: true)

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.occupiedBits, [])
        XCTAssertEqual(policy.referencedBits, [])
        XCTAssertEqual(policy.cursors.insert, .init(0))
        XCTAssertEqual(policy.cursors.remove, .init(0))
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
