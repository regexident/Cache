import XCTest

@testable import Cache

extension RRPolicy {
    internal var chunkBits: [RRPolicy.Bits] {
        self.chunks.map { chunk in
            chunk.bits
        }
    }
}

final class RRPolicyTests: XCTestCase {
    typealias Policy = RRPolicy
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
        XCTAssertEqual(policy.chunks, [])
    }

    func testInsertIntoEmptyPolicy() throws {
        var policy = self.policy()

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 0)
        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.chunkBits, [0b00000001])
    }

    func testInsertIntoDenselyFilledPolicy() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00000111])

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.chunkBits, [0b00001111])
    }

    func testInsertIntoSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011001]
        )

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 1)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.chunkBits, [0b00011011])
    }

    func testInsertIntoSaturatedPolicy() {
        var policy = Policy(
            count: 8,
            chunkBits: [0b11111111]
        )

        let index = policy.insert()

        XCTAssertEqual(index.absoluteBitIndex, 8)
        XCTAssertEqual(policy.count, 9)
        XCTAssertEqual(policy.chunkBits, [0b11111111, 0b00000001])
    }

    func testUse() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010]
        )

        policy.use(.init(absoluteBitIndex: 3))

        // RRPolicy does not do anything on `.use(…)`
        // so we shouldn't see any change either:

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00011010])
    }

    func testRemoveFromFullPolicy() throws {
        var policy = Policy(
            count: 8,
            chunkBits: [0b11111111]
        )

        let index = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 3)
        XCTAssertEqual(policy.count, 7)
        XCTAssertEqual(policy.chunkBits, [0b11110111])
    }

    func testRemoveFromDenselyFilledPolicy() throws {
        var policy = self.policy(count: 3)

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00000111])

        let index = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 1)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.chunkBits, [0b00000101])
    }

    func testRemoveFromSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010]
        )

        let index = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 1)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.chunkBits, [0b00011000])
    }

    func testRemoveIndex() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010]
        )

        policy.remove(.init(absoluteBitIndex: 1))

        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.chunkBits, [0b00011000])

        policy.remove(.init(absoluteBitIndex: 4))

        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.chunkBits, [0b00001000])

        policy.remove(.init(absoluteBitIndex: 3))

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
