import XCTest

@testable import Cache

final class BitChunkTests: XCTestCase {
    typealias Bits = UInt8
    typealias Chunk = BitChunk<Bits>

    func testInit() throws {
        let chunk = Chunk()

        XCTAssertEqual(chunk.bits, 0b0)
    }

    func testInitBits() throws {
        let chunk = Chunk(bits: 0b01010101)

        XCTAssertEqual(chunk.bits, 0b01010101)
    }

    func testBitWidth() throws {
        XCTAssertEqual(Chunk.bitWidth, 8)
    }

    func testZeros() throws {
        let chunk: Chunk = .zeros

        XCTAssertEqual(chunk.bits, 0b00000000)
    }

    func testOnes() throws {
        let chunk: Chunk = .ones

        XCTAssertEqual(chunk.bits, 0b11111111)
    }

    func testIsEmpty() throws {
        let emptyChunk = Chunk(bits: 0b00000000)

        XCTAssertTrue(emptyChunk.isEmpty)

        let nonEmptyChunk = Chunk(bits: 0b01010101)

        XCTAssertFalse(nonEmptyChunk.isEmpty)
    }

    func testIsFull() throws {
        let fullChunk = Chunk(bits: 0b11111111)

        XCTAssertTrue(fullChunk.isFull)

        let nonFullChunk = Chunk(bits: 0b01010101)

        XCTAssertFalse(nonFullChunk.isFull)
    }

    func testCount() throws {
        let emptyChunk = Chunk(bits: 0b00000000)

        XCTAssertEqual(emptyChunk.count, 0)

        let fullChunk = Chunk(bits: 0b11111111)

        XCTAssertEqual(fullChunk.count, 8)

        let semiFullChunk = Chunk(bits: 0b01010101)

        XCTAssertEqual(semiFullChunk.count, 4)
    }

    func testMaskIndex() throws {
        let zeroIndexChunk = Chunk.mask(index: 0)

        XCTAssertEqual(zeroIndexChunk.bits, 0b00000001)

        let threeIndexChunk = Chunk.mask(index: 3)

        XCTAssertEqual(threeIndexChunk.bits, 0b00001000)

        let sevenIndexChunk = Chunk.mask(index: 7)

        XCTAssertEqual(sevenIndexChunk.bits, 0b10000000)
    }

    func testMaskRange() throws {
        let chunk = Chunk.mask(range: 2..<4)

        XCTAssertEqual(chunk.bits, 0b00001100)
    }

    func testMaskRangeFrom() throws {
        let chunk = Chunk.mask(range: 2...)

        XCTAssertEqual(chunk.bits, 0b11111100)
    }

    func testMaskRangeUpTo() throws {
        let chunk = Chunk.mask(range: ..<2)

        XCTAssertEqual(chunk.bits, 0b00000011)
    }

    func testMaskRangeThrough() throws {
        let chunk = Chunk.mask(range: ...2)

        XCTAssertEqual(chunk.bits, 0b00000111)
    }

    func testIsZerosAtMask() throws {
        let chunk = Chunk(bits: 0b00010111)

        XCTAssertFalse(
            chunk.isZeros(atMask: 0b00000111)
        )

        XCTAssertFalse(
            chunk.isZeros(atMask: 0b00111000)
        )

        XCTAssertTrue(
            chunk.isZeros(atMask: 0b11100000)
        )
    }

    func testIsOnesAtMask() throws {
        let chunk = Chunk(bits: 0b00010111)

        XCTAssertTrue(
            chunk.isOnes(atMask: 0b00000111)
        )

        XCTAssertFalse(
            chunk.isOnes(atMask: 0b00111000)
        )

        XCTAssertFalse(
            chunk.isOnes(atMask: 0b11100000)
        )
    }

    func testHasZerosAtMask() throws {
        let chunk = Chunk(bits: 0b00010111)

        XCTAssertFalse(
            chunk.hasZeros(atMask: 0b00000111)
        )

        XCTAssertTrue(
            chunk.hasZeros(atMask: 0b00111000)
        )

        XCTAssertTrue(
            chunk.hasZeros(atMask: 0b11100000)
        )
    }

    func testHasOnesAtMask() throws {
        let chunk = Chunk(bits: 0b00010111)

        XCTAssertTrue(
            chunk.hasOnes(atMask: 0b00000111)
        )

        XCTAssertTrue(
            chunk.hasOnes(atMask: 0b00111000)
        )

        XCTAssertFalse(
            chunk.hasOnes(atMask: 0b11100000)
        )
    }

    func testFirstOneInRangeFrom() throws {
        let chunk = Chunk(bits: 0b00010101)

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 0...),
            0
        )

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 1...),
            2
        )

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 2...),
            2
        )

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 3...),
            4
        )

        XCTAssertNil(
            chunk.indexOfFirstOne(inRange: 5...)
        )
    }

    func testFirstOneInRange() throws {
        let chunk = Chunk(bits: 0b00010101)

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 0..<3),
            0
        )

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 1..<3),
            2
        )

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 2..<3),
            2
        )

        XCTAssertEqual(
            chunk.indexOfFirstOne(inRange: 3..<3),
            4
        )

        XCTAssertNil(
            chunk.indexOfFirstOne(inRange: 5..<8)
        )
    }

//    static var allTests = [
//        ("testInit", testInit),
//    ]
}
