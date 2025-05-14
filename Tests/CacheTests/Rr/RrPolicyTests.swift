import XCTest

import PseudoRandom

@testable import Cache

final class RrPolicyTests: XCTestCase {
    typealias Bits = UInt8
    typealias Generator = SplitMix64
    typealias Policy = CustomRrPolicy<Bits, Generator>
    typealias Index = Policy.Index

    static func makeGenerator() -> SplitMix64 {
        .init(seed: 0)
    }

    func testInit() throws {
        let policy = Policy(generator: Self.makeGenerator())

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.chunks, [])
    }

    func testHasCapacity() throws {
        let policy = Policy(generator: Self.makeGenerator())

        XCTAssertTrue(policy.hasCapacity(forMetadata: nil))
        XCTAssertTrue(policy.hasCapacity(forMetadata: .default))
    }

    func testStateOf() throws {
        var policy = Policy(generator: Self.makeGenerator())

        let index = policy.insert(metadata: .default)

        XCTAssertEqual(policy.state(of: index), .alive)
    }

    func testInsertIntoEmptyPolicy() throws {
        var policy = Policy(generator: Self.makeGenerator())

        let index = policy.insert(metadata: .default)

        XCTAssertEqual(index.absoluteBitIndex, 0)

        XCTAssertFalse(policy.isEmpty)
        XCTAssertEqual(policy.count, 1)
        XCTAssertEqual(policy.chunkBits, [0b00000001])
    }

    func testInsertIntoDenselyFilledPolicy() throws {
        var policy = Policy(generator: Self.makeGenerator())

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

        XCTAssertFalse(policy.isEmpty)
        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00000111])

        let index = policy.insert(metadata: .default)

        XCTAssertEqual(index.absoluteBitIndex, 3)

        XCTAssertFalse(policy.isEmpty)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.chunkBits, [0b00001111])
    }

    func testInsertIntoSparselyFilledPolicy() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011001],
            generator: Self.makeGenerator()
        )

        let index = policy.insert(metadata: .default)

        XCTAssertEqual(index.absoluteBitIndex, 1)
        XCTAssertEqual(policy.count, 4)
        XCTAssertEqual(policy.chunkBits, [0b00011011])
    }

    func testInsertIntoSaturatedPolicy() {
        var policy = Policy(
            count: 8,
            chunkBits: [0b11111111],
            generator: Self.makeGenerator()
        )

        let index = policy.insert(metadata: .default)

        XCTAssertEqual(index.absoluteBitIndex, 8)
        XCTAssertEqual(policy.count, 9)
        XCTAssertEqual(policy.chunkBits, [0b11111111, 0b00000001])
    }

    func testUse() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010],
            generator: Self.makeGenerator()
        )

        let index = policy.use(.init(3), metadata: .default)

        XCTAssertEqual(index, .init(3))

        // RrPolicy does not do anything on `.use(…)`
        // so we shouldn't see any change either:

        XCTAssertEqual(policy.count, 3)
        XCTAssertEqual(policy.chunkBits, [0b00011010])
    }

    func testRemoveFromFullPolicy() throws {
        var policy = Policy(
            count: 8,
            chunkBits: [0b11111111],
            generator: Self.makeGenerator()
        )

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 7)
        XCTAssertEqual(policy.count, 7)
        XCTAssertEqual(policy.chunkBits, [0b01111111])
    }

    func testRemoveFromDenselyFilledPolicy() throws {
        var policy = Policy(generator: Self.makeGenerator())

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

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
            chunkBits: [0b00011010],
            generator: Self.makeGenerator()
        )

        let (index, _) = try XCTUnwrap(policy.remove())

        XCTAssertEqual(index.absoluteBitIndex, 1)
        XCTAssertEqual(policy.count, 2)
        XCTAssertEqual(policy.chunkBits, [0b00011000])
    }

    func testRemoveIndex() throws {
        var policy = Policy(
            count: 3,
            chunkBits: [0b00011010],
            generator: Self.makeGenerator()
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

    func testRemoveExpired() throws {
        var policy = Policy(generator: Self.makeGenerator())

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

        policy.removeExpired { index in
            XCTFail("Indices should not expire")
        }

        XCTAssertEqual(policy.count, 3)
    }

    func testRemoveAll() throws {
        var policy = Policy(generator: Self.makeGenerator())

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

        policy.removeAll()

        XCTAssertEqual(policy.count, 0)
        XCTAssertEqual(policy.chunkBits, [])
        XCTAssertEqual(policy.capacity, 0)
    }

    func testRemoveAllKeepingCapacity() throws {
        var policy = Policy(generator: Self.makeGenerator())

        for _ in 0..<3 {
            let _ = policy.insert(metadata: .default)
        }

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
