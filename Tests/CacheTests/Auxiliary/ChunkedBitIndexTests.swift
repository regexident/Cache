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

    func testChunkIndexGiven() throws {
        let absoluteBitIndex: Int = 1234
        let index = Index(absoluteBitIndex: absoluteBitIndex)

        XCTAssertEqual(
            index.chunkIndex(given: UInt8.self),
            absoluteBitIndex / 8
        )
        XCTAssertEqual(
            index.chunkIndex(given: UInt16.self),
            absoluteBitIndex / 16
        )
        XCTAssertEqual(
            index.chunkIndex(given: UInt32.self),
            absoluteBitIndex / 32
        )
        XCTAssertEqual(
            index.chunkIndex(given: UInt64.self),
            absoluteBitIndex / 64
        )
    }

    func testBitIndexGiven() throws {
        let absoluteBitIndex: Int = 1234
        let index = Index(absoluteBitIndex: absoluteBitIndex)
        XCTAssertEqual(
            index.bitIndex(given: UInt8.self),
            absoluteBitIndex % 8
        )
        XCTAssertEqual(
            index.bitIndex(given: UInt16.self),
            absoluteBitIndex % 16
        )
        XCTAssertEqual(
            index.bitIndex(given: UInt32.self),
            absoluteBitIndex % 32
        )
        XCTAssertEqual(
            index.bitIndex(given: UInt64.self),
            absoluteBitIndex % 64
        )
    }

    func testBitsPerBitIndexGiven() throws {
        let bitsUInt8 = Index.bitsPerBitIndex(given: UInt8.self)
        XCTAssertEqual(bitsUInt8, 3)

        let bitsUInt16 = Index.bitsPerBitIndex(given: UInt16.self)
        XCTAssertEqual(bitsUInt16, 4)

        let bitsUInt32 = Index.bitsPerBitIndex(given: UInt32.self)
        XCTAssertEqual(bitsUInt32, 5)

        let bitsUInt64 = Index.bitsPerBitIndex(given: UInt64.self)
        XCTAssertEqual(bitsUInt64, 6)
    }

    func testBitIndexMaskGiven() throws {
        let maskUInt8 = Index.bitIndexMask(given: UInt8.self)
        XCTAssertEqual(maskUInt8, 0b00000111)

        let maskUInt16 = Index.bitIndexMask(given: UInt16.self)
        XCTAssertEqual(maskUInt16, 0b00001111)

        let maskUInt32 = Index.bitIndexMask(given: UInt32.self)
        XCTAssertEqual(maskUInt32, 0b00011111)

        let maskUInt64 = Index.bitIndexMask(given: UInt64.self)
        XCTAssertEqual(maskUInt64, 0b00111111)
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
        ("testChunkIndexGiven", testChunkIndexGiven),
        ("testBitIndexGiven", testBitIndexGiven),
        ("testBitsPerBitIndexGiven", testBitsPerBitIndexGiven),
        ("testBitIndexMaskGiven", testBitIndexMaskGiven),
        ("testAdvancedBy", testAdvancedBy),
    ]
}
