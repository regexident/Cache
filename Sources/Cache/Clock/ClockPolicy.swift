// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Logging

public typealias ClockCache<Key, Value> = CustomClockCache<Key, Value, Int, UInt64>
where
    Key: Hashable

public typealias CustomClockCache<Key, Value, Cost, Bits> = CustomCache<Key, Value, Cost, CustomClockPolicy<Bits>>
where
    Key: Hashable,
    Cost: Comparable & Numeric,
    Bits: FixedWidthInteger & UnsignedInteger

public typealias ClockIndex = ChunkedBitIndex

public typealias ClockPolicy = CustomClockPolicy<UInt64>

public struct CustomClockPolicy<Bits>: CachePolicy
where
    Bits: FixedWidthInteger & UnsignedInteger
{
    public typealias Index = ClockIndex

    internal typealias Chunk = BitChunk<Bits>
    internal typealias Block = ClockBlock<Bits>

    internal struct Cursors {
        public typealias Index = ClockIndex

        internal var insert: Index = .init()
        internal var remove: Index = .init()
    }

    public var capacity: Int {
        return self.blocks.capacity * Chunk.bitWidth
    }

    fileprivate var isFull: Bool {
        self.count == self.blocks.count * Chunk.bitWidth
    }

    public var isEmpty: Bool {
        self.count == 0
    }

    public private(set) var count: Int

    internal private(set) var blocks: [Block]
    internal private(set) var cursors: Cursors

    /// Creates an empty cache policy with no preallocated space.
    public init() {
        self.init(minimumCapacity: 0)
    }

    /// Creates an empty cache policy with preallocated space
    /// for at least the specified number of elements.
    ///
    /// - Note:
    ///   For performance reasons, the size of the newly allocated
    ///   storage might be greater than the requested capacity.
    ///   Use the policy's `capacity` property to determine the size
    ///   of the new storage.
    ///
    /// - Parameters:
    ///   - minimumCapacity:
    ///     The requested number of elements to store.
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

        // Calculate required number of blocks, rounding up:
        let blockCount = Self.blocksFor(count: capacity)

        let zeroedBlocks: [Block] = Array(
            repeating: .init(),
            count: blockCount
        )

        self.init(
            count: 0,
            blocks: zeroedBlocks,
            cursors: .init()
        )
    }

    internal init(
        count: Int,
        blocks: [Block],
        cursors: Cursors
    ) {
        self.count = count
        self.blocks = blocks
        self.cursors = cursors
    }

    public mutating func insert() -> Index {
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            #if DEBUG
            assert(self.isValid())
            #endif
        }

        if self.isFull {
            self.blocks.append(.init())
        }

        let chunkCount = self.blocks.count

        let (chunkCursor, bitCursor) = self.cursors.insert.indices(
            given: Bits.self
        )
        var chunkIndex: Int = chunkCursor
        var bitIndex: Int = bitCursor

        var didFindVictim: Bool = false

        let chunkOffsetRange = 0..<chunkCount
        for chunkOffset in chunkOffsetRange {
            chunkIndex = (chunkCursor + chunkOffset) % chunkCount
            let range = self.rangeForChunk(
                at: chunkOffset,
                in: chunkOffsetRange,
                cursor: bitCursor
            )

            if let index = self.blocks[chunkIndex].indexOfFirstUnnoccupied(
                range: range
            ) {
                bitIndex = index
                didFindVictim = true
                break
            }
        }

        assert(didFindVictim)

        let index = Self.index(chunk: chunkIndex, bit: bitIndex)
        let indexMask = Chunk.mask(index: bitIndex)

        assert(self.blocks[chunkIndex].isVacant(mask: indexMask))

        self.blocks[chunkIndex].occupy(mask: indexMask)
        self.blocks[chunkIndex].reference(mask: indexMask)

        self.cursors.insert = index.advanced(by: 1)
        self.count += 1

        return index
    }

    public mutating func use(_ index: Index) {
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            #if DEBUG
            assert(self.isValid())
            #endif
        }

        let (chunkIndex, bitIndex) = index.indices(given: Bits.self)
        let indexMask = Chunk.mask(index: bitIndex)

        assert(self.blocks[chunkIndex].isOccupied(mask: indexMask))

        self.blocks[chunkIndex].reference(mask: indexMask)
    }

    public mutating func remove() -> Index? {
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            #if DEBUG
            assert(self.isValid())
            #endif
        }

        let chunkCount = self.blocks.count

        let (chunkCursor, bitCursor) = self.cursors.remove.indices(
            given: Bits.self
        )
        var chunkIndex: Int = chunkCursor
        var bitIndex: Int = bitCursor

        var didFindVictim: Bool = false

        let chunkOffsetRange = 0..<(chunkCount + 1)
        for chunkOffset in chunkOffsetRange {
            chunkIndex = (chunkCursor + chunkOffset) % chunkCount
            let range = self.rangeForChunk(
                at: chunkOffset,
                in: chunkOffsetRange,
                cursor: bitCursor
            )
            let mask = Chunk.mask(range: range)
            if let index = self.blocks[chunkIndex].indexOfFirstUnreferenced(
                range: range
            ) {
                bitIndex = index
                let mask = Chunk.mask(range: (range.lowerBound)...index)
                self.blocks[chunkIndex].dereference(mask: mask)
                didFindVictim = true
                break
            }
            self.blocks[chunkIndex].dereference(mask: mask)
        }

        assert(didFindVictim)

        let index = Self.index(chunk: chunkIndex, bit: bitIndex)
        let indexMask = Chunk.mask(index: bitIndex)

        assert(self.blocks[chunkIndex].isOccupied(mask: indexMask))

        self.blocks[chunkIndex].evict(mask: indexMask)

        self.cursors.remove = index.advanced(by: 1)
        self.count -= 1

        return index
    }

    public mutating func remove(_ index: Index) {
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            #if DEBUG
            assert(self.isValid())
            #endif
        }

        let (chunkIndex, bitIndex) = index.indices(given: Bits.self)
        let indexMask = Chunk.mask(index: bitIndex)

        assert(self.blocks[chunkIndex].isOccupied(mask: indexMask))

        self.blocks[chunkIndex].evict(mask: indexMask)

        self.count -= 1
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            #if DEBUG
            assert(self.isValid())
            #endif
        }

        self.count = 0
        self.blocks.removeAll(keepingCapacity: keepCapacity)
        self.cursors = .init()
    }

    //                           ┌ startIndex
    //           ┌──────────┬────┼─────┬──────────┬──────────┐
    // chunks:   │ XXXXXXXX │ XXXXXXXX │ XXXXXXXX │ XXXXXXXX │
    //           ├──────────┼──────────┼──────────┼──────────┤
    // mask 0:   │          │ 00011111 │          │          │
    // mask 1:   │          │    └───┘ │ 11111111 │          │
    // mask 2:   │          │          │ └──────┘ │ 11111111 │─┐
    // mask 3: ┌→│ 11111111 │          │          │ └──────┘ │ │
    // mask 4: │ │ └──────┘ │ 11100000 │          │          │ │
    //         │ │          │ └─┘      │          │          │ │
    //         │ └──────────┴──────────┴──────────┴──────────┘ │
    //         └───────────────────────────────────────────────┘
    private func rangeForChunk(
        at index: Int,
        in range: Range<Int>,
        cursor: Int
    ) -> Range<Int> {
        if index == range.lowerBound {
            return cursor..<Chunk.bitWidth
        } else if index == range.upperBound {
            return 0..<(cursor + 1)
        } else {
            return 0..<Chunk.bitWidth
        }
    }

    private static func blocksFor(count: Int) -> Int {
        let bitWidth = Chunk.bitWidth
        // Calculate required number of blocks, by rounding up:
        return (count + (bitWidth - 1)) / bitWidth
    }

    private static func index(chunk: Int, bit: Int) -> Index {
        .init(
            given: Bits.self,
            chunkIndex: chunk,
            bitIndex: bit
        )
    }

    private func logState(to logger: Logger = logger) {
        guard logger.logLevel <= .trace else {
            return
        }

        let occupied = self.blocks.lazy.map {
            $0.occupied.bits
        }.map {
            "\($0, radix: .binary, toWidth: Bits.bitWidth)"
        }.joined(separator: ", ")

        let referenced = self.blocks.lazy.map {
            $0.referenced.bits
        }.map {
            "\($0, radix: .binary, toWidth: Bits.bitWidth)"
        }.joined(separator: ", ")

        let count = self.count

        logger.trace("count: \(count)")
        logger.trace("cursors.insert: \(self.cursors.insert)")
        logger.trace("cursors.remove: \(self.cursors.remove)")
        logger.trace("occupied:   [\(occupied)]")
        logger.trace("referenced: [\(referenced)]")
    }

    internal func isValid() -> Bool {
        guard shouldValidate else {
            return true
        }

        var count: Int = 0
        for block in self.blocks {
            guard block.isValid() else {
                return false
            }
            count += block.occupied.count
        }

        guard count == self.count else {
            return false
        }

        return true
    }
}
