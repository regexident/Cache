// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public typealias RrCache<Key, Value> = CustomRrCache<Key, Value, Int, UInt64>
where
    Key: Hashable

public typealias CustomRrCache<Key, Value, Cost, Bits> = CustomCache<Key, Value, Cost, CustomRrPolicy<Bits>>
where
    Key: Hashable,
    Cost: Comparable & Numeric,
    Bits: FixedWidthInteger & UnsignedInteger

public typealias RrIndex = ChunkedBitIndex

public typealias RrPolicy = CustomRrPolicy<UInt64>

public struct CustomRrPolicy<Bits>: CachePolicy
where
    Bits: FixedWidthInteger & UnsignedInteger
{
    public typealias Index = RrIndex

    internal typealias Chunk = BitChunk<Bits>

    public var isEmpty: Bool {
        self.count == 0
    }

    public var capacity: Int {
        self.chunks.capacity * Chunk.bitWidth
    }

    public private(set) var count: Int
    internal private(set) var chunks: [Chunk]

    public init() {
        self.init(minimumCapacity: 0)
    }

    public init(minimumCapacity: Int) {
        assert(minimumCapacity >= 0)

        // Next smallest greater than or equal power of 2:
        let capacity: Int

        if minimumCapacity > 0 {
            let leadingZeros = minimumCapacity.leadingZeroBitCount
            capacity = 0b1 << (Int.bitWidth - leadingZeros)
        } else {
            capacity = 0
        }

        // Calculate required number of chunks, rounding up:
        let chunkCount = Self.chunksFor(count: capacity)

        let chunks: [Chunk] = Array(
            repeating: .init(),
            count: chunkCount
        )

        self.init(
            count: 0,
            chunks: chunks
        )
    }

    internal init(
        count: Int,
        chunkBits: [Bits]
    ) {
        self.init(
            count: count,
            chunks: chunkBits.map { .init(bits: $0) }
        )
    }

    internal init(
        count: Int,
        chunks: [Chunk]
    ) {
        self.count = count
        self.chunks = chunks
    }

    public mutating func insert() -> Index {
        if self.count == self.chunks.count * Chunk.bitWidth {
            self.chunks.append(.init())
        }

        let startIndex = self.randomStartIndex()
        var (chunkIndex, startBitIndex) = startIndex.indices(
            given: Bits.self
        )

        // Skip over full chunks:
        for _ in 0...self.chunks.count {
            let mask = Chunk.mask(range: startBitIndex..<Chunk.bitWidth)
            guard self.chunks[chunkIndex].isOnes(atMask: mask) else {
                break
            }
            startBitIndex = 0
            chunkIndex += 1
        }

        let chunk = self.chunks[chunkIndex]
        let range = startBitIndex..<Bits.bitWidth

        let endBitIndexOrNil = chunk.indexOfFirstZero(inRange: range)
        guard let endBitIndex = endBitIndexOrNil else {
            fatalError("Expected vacancy, found none")
        }

        let mask = Chunk.mask(range: startBitIndex...endBitIndex)
        self.chunks[chunkIndex].setOnes(atMask: mask)
        let index = Self.index(chunk: chunkIndex, bit: endBitIndex)
        self.count += 1

        return index
    }

    public mutating func use(_ index: Index) {
        // ignored
    }

    public mutating func remove() -> Index? {
        let startIndex = self.randomStartIndex()
        var (chunkIndex, startBitIndex) = startIndex.indices(
            given: Bits.self
        )

        // Skip over full chunks:
        for _ in 0...self.chunks.count {
            let mask = Chunk.mask(range: startBitIndex..<Chunk.bitWidth)
            guard self.chunks[chunkIndex].isZeros(atMask: mask) else {
                break
            }
            startBitIndex = 0
            chunkIndex += 1
        }

        let chunk = self.chunks[chunkIndex]
        let range = startBitIndex..<Bits.bitWidth

        let endBitIndexOrNil = chunk.indexOfFirstOne(inRange: range)
        guard let endBitIndex = endBitIndexOrNil else {
            fatalError("Expected occupancy, found none")
        }

        let mask = Chunk.mask(range: startBitIndex...endBitIndex)
        self.chunks[chunkIndex].setZeros(atMask: mask)
        let index = Self.index(chunk: chunkIndex, bit: endBitIndex)
        self.count -= 1

        return index
    }

    public mutating func remove(_ index: Index) {
        let (chunkIndex, bitIndex) = index.indices(given: Bits.self)
        let mask = Chunk.mask(index: bitIndex)
        self.chunks[chunkIndex].setZeros(atMask: mask)
        self.count -= 1
    }

    @inlinable
    @inline(__always)
    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.count = 0
        self.chunks.removeAll(keepingCapacity: keepCapacity)
    }

    private static func chunksFor(count: Int) -> Int {
        let bitWidth = Chunk.bitWidth
        // Calculate required number of chunks, by rounding up:
        return (count + (bitWidth - 1)) / bitWidth
    }

    private static func index(chunk: Int, bit: Int) -> Index {
        .init(
            given: Bits.self,
            chunkIndex: chunk,
            bitIndex: bit
        )
    }

    private func randomStartIndex() -> Index {
        var prng = SplitMix64(state: .init(self.count))
        let uint = UInt(truncatingIfNeeded: prng.next())
        let int = Int(truncatingIfNeeded: uint >> 1)
        let count = self.count
        let index = (count != 0) ? (int % count) : 0
        return .init(absoluteBitIndex: index)
    }

    private func isValid() -> Bool {
        let validCount = self.chunks.reduce(0) {
            $0 + $1.count
        } == self.count

        guard validCount else {
            return false
        }

        return true
    }
}
