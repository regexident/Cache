import XCTest

import PseudoRandom

@testable import Cache

final class RrPolicyTests: XCTestCase {
    typealias Bits = UInt8
    typealias Generator = SplitMix64
    typealias Policy = CustomRrPolicy<Bits, Generator>
    typealias Index = Policy.Index

    func policy(
        count: Int = 0
    ) -> Policy {
        var policy = Policy()

        for _ in 0..<count {
            let _ = policy.insert(payload: .default)
        }

        return policy
    }

    func testInit() throws {
        let policy = self.policy()

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.chunks, [])
    }

    func testInsertIntoEmptyPolicy() throws {
        var policy = self.policy()

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 0)
        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.chunkBits, [0b00000001])
    }

    func testInsertIntoDenselyFilledPolicy() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00000111])

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.chunkBits, [0b00001111])
    }

    func testInsertIntoSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011001]
        )

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 1)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.chunkBits, [0b00011011])
    }

    func testInsertIntoSaturatedPolicy() {
        var policy = Policy(
            count: 8,
            chunkBits: [0b11111111]
        )

        let index = policy.insert(payload: .default)

        XCTAssertEqual(index.absoluteBitIndex, 8)
        XCTAssertEqual(policy.count, 9)
        XCTAssertEqual(policy.chunkBits, [0b11111111, 0b00000001])
    }

    func testUse() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010]
        )

        policy.use(.init(3))

        // RrPolicy does not do anything on `.use(…)`
        // so we shouldn't see any change either:

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00011010])
    }

    func testRemoveFromFullPolicy() throws {
        var policy = Policy(
            count: 8,
            chunkBits: [0b11111111]
        )

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 7)
        XCTAssertEqual(policy.count, 7)
        XCTAssertEqual(policy.chunkBits, [0b01111111])
    }

    func testRemoveFromDenselyFilledPolicy() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00000111])

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 2)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.chunkBits, [0b00000011])
    }

    func testRemoveFromSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010]
        )

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 1)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.chunkBits, [0b00011000])
    }

    func testRemoveIndex() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010]
        )

        let _ = policy.remove(.init(1))

        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.chunkBits, [0b00011000])

        let _ = policy.remove(.init(4))

        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.chunkBits, [0b00001000])

        let _ = policy.remove(.init(3))

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.chunkBits, [0b00000000])
    }

    func testRemoveAll() throws {
        var policy = self.policy(count: 3)

        policy.removeAll()

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.chunkBits, [])
        XCTAssertEqual(policy.capacity, 0)
    }

    func testRemoveAllKeepingCapacity() throws {
        var policy = self.policy(count: 3)

        let capacity = policy.capacity

        policy.removeAll(keepingCapacity: true)

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.chunkBits, [])
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
