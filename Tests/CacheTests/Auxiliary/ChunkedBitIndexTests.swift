import XCTest

@testable import Cache

final class ChunkedBitIndexTests: XCTestCase {
    typealias Chunk = UInt8
    typealias Index = ChunkedBitIndex

    func testInit() throws {
        let index = Index()

        XCTAssertEqual(index.absoluteBitIndex, 0)
    }

    func testInitAbsoluteBitIndex() throws {
        let index = Index(absoluteBitIndex: 42)

        XCTAssertEqual(index.absoluteBitIndex, 42)
    }

    func testInitGivenChunkIndexBitIndex() throws {
        let absoluteBitIndex: Int = 1234

        XCTAssertEqual(
            Index(
                given: UInt8.self,
                chunkIndex: absoluteBitIndex / 8,
                bitIndex: absoluteBitIndex % 8
            ).absoluteBitIndex,
            absoluteBitIndex
        )
        XCTAssertEqual(
            Index(
                given: UInt16.self,
                chunkIndex: absoluteBitIndex / 16,
                bitIndex: absoluteBitIndex % 16
            ).absoluteBitIndex,
            absoluteBitIndex
        )
        XCTAssertEqual(
            Index(
                given: UInt32.self,
                chunkIndex: absoluteBitIndex / 32,
                bitIndex: absoluteBitIndex % 32
            ).absoluteBitIndex,
            absoluteBitIndex
        )
        XCTAssertEqual(
            Index(
                given: UInt64.self,
                chunkIndex: absoluteBitIndex / 64,
                bitIndex: absoluteBitIndex % 64
            ).absoluteBitIndex,
            absoluteBitIndex
        )
    }

    func testIndicesGiven() throws {
        let absoluteBitIndex: Int = 1234
        let index = Index(absoluteBitIndex: absoluteBitIndex)

        let indicesUInt8 = index.indices(given: UInt8.self)

        XCTAssertEqual(indicesUInt8.chunk, absoluteBitIndex / 8)
        XCTAssertEqual(indicesUInt8.bit, absoluteBitIndex % 8)

        let indicesUInt16 = index.indices(given: UInt16.self)

        XCTAssertEqual(indicesUInt16.chunk, absoluteBitIndex / 16)
        XCTAssertEqual(indicesUInt16.bit, absoluteBitIndex % 16)

        let indicesUInt32 = index.indices(given: UInt32.self)

        XCTAssertEqual(indicesUInt32.chunk, absoluteBitIndex / 32)
        XCTAssertEqual(indicesUInt32.bit, absoluteBitIndex % 32)

        let indicesUInt64 = index.indices(given: UInt64.self)

        XCTAssertEqual(indicesUInt64.chunk, absoluteBitIndex / 64)
        XCTAssertEqual(indicesUInt64.bit, absoluteBitIndex % 64)
    }

    func testAdvancedBy() throws {
        let index = Index(absoluteBitIndex: 42)

        func applying(
            index: Index,
            _ closure: (inout Index) -> Void
        ) -> Index {
            var index = index
            closure(&index)
            return index
        }

        // Subtracting while staying in positive range:
        XCTAssertEqual(
            applying(index: index) {
                $0.absoluteBitIndex &-= 42
            },
            .init(absoluteBitIndex: 0)
        )

        // Adding while staying in positive range:
        XCTAssertEqual(
            applying(index: index) {
                $0.absoluteBitIndex &+= 42
            },
            .init(absoluteBitIndex: 84)
        )

        // Subtracting while passing zero into negative range:
        XCTAssertEqual(
            applying(index: index) {
                $0.absoluteBitIndex &-= 84
            },
            .init(absoluteBitIndex: .max - 42 + 1)
        )

        // Adding while passing Int.Max into negative range:
        XCTAssertEqual(
            applying(index: index) {
                $0.absoluteBitIndex &+= Int.max
            },
            .init(absoluteBitIndex: 42 - 1)
        )
    }

    static var allTests = [
        ("testInit", testInit),
        ("testInitAbsoluteBitIndex", testInitAbsoluteBitIndex),
        ("testInitGivenChunkIndexBitIndex", testInitGivenChunkIndexBitIndex),
        ("testIndicesGiven", testIndicesGiven),
        ("testAdvancedBy", testAdvancedBy),
    ]
}
