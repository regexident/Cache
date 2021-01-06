// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Logging

public typealias RrCache<Key, Value> = CustomRrCache<Key, Value, UInt64, SystemRandomNumberGenerator>
where
    Key: Hashable

public typealias CustomRrCache<Key, Value, Bits, Generator> = CustomCache<Key, Value, CustomRrPolicy<Bits, Generator>>
where
    Key: Hashable,
    Bits: FixedWidthInteger & UnsignedInteger,
    Generator: InitializableRandomNumberGenerator

public typealias RrPolicy = CustomRrPolicy<UInt64, SystemRandomNumberGenerator>

public struct CustomRrPolicy<Bits, Generator>: CachePolicy
where
    Bits: FixedWidthInteger & UnsignedInteger,
    Generator: InitializableRandomNumberGenerator
{
    public typealias Index = ChunkedBitIndex
    public typealias Payload = NoPayload

    internal typealias Chunk = BitChunk<Bits>

    // Since there is only a single possible instance
    // of `Payload` (aka `NoPayload`) we
    // access it via `Self.globalPayload` to make
    // things more explicit.
    private static var globalPayload: Payload {
        .init()
    }

    public var isEmpty: Bool {
        self.count == 0
    }

    public var capacity: Int {
        self.chunks.capacity * Chunk.bitWidth
    }

    public private(set) var count: Int
    internal private(set) var chunks: [Chunk]
    internal private(set) var generator: Generator

    public init() {
        self.init(generator: .init())
    }

    public init(generator: Generator) {
        self.init(
            minimumCapacity: 0,
            generator: generator
        )
    }

    public init(
        minimumCapacity: Int = 0
    ) {
        self.init(
            minimumCapacity: minimumCapacity,
            generator: .init()
        )
    }

    public init(
        minimumCapacity: Int = 0,
        generator: Generator
    ) {
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
            chunks: chunks,
            generator: generator
        )
    }

    internal init(
        count: Int,
        chunks: [Chunk],
        generator: Generator
    ) {
        self.count = count
        self.chunks = chunks
        self.generator = generator
    }

    public func hasCapacity(
        forPayload payload: Payload?
    ) -> Bool {
        true
    }

    public func state(of index: Index) -> CachePolicyIndexState {
        .alive
    }

    public mutating func insert(payload: Payload) -> Index {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        if self.count == self.chunks.count * Chunk.bitWidth {
            self.chunks.append(.init())
        }

        let startIndex = self.randomStartIndex()
        var (chunkIndex, startBitIndex) = startIndex.indices(
            given: Bits.self
        )
        let chunkCount = self.chunks.count

        for _ in 0...chunkCount {
            let mask = Chunk.mask(range: startBitIndex..<Chunk.bitWidth)
            guard self.chunks[chunkIndex].isOnes(atMask: mask) else {
                break
            }
            startBitIndex = 0
            chunkIndex += 1
            if chunkIndex == chunkCount {
                chunkIndex = 0
            }
        }

        let range = startBitIndex..<Bits.bitWidth
        let chunk = self.chunks[chunkIndex]
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

    public mutating func use(
        _ index: Index,
        payload: Payload
    ) -> Index {
        logger.trace("\(type(of: self)).\(#function)")

        return index
    }

    public mutating func remove() -> (index: Index, payload: Payload)? {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        let startIndex = self.randomStartIndex()
        var (chunkIndex, startBitIndex) = startIndex.indices(
            given: Bits.self
        )
        let chunkCount = self.chunks.count

        for _ in 0...chunkCount {
            let mask = Chunk.mask(range: startBitIndex..<Chunk.bitWidth)
            guard self.chunks[chunkIndex].isZeros(atMask: mask) else {
                break
            }
            startBitIndex = 0
            chunkIndex += 1
            if chunkIndex == chunkCount {
                chunkIndex = 0
            }
        }

        let range = startBitIndex..<Bits.bitWidth
        let chunk = self.chunks[chunkIndex]
        let endBitIndexOrNil = chunk.indexOfFirstOne(inRange: range)
        guard let endBitIndex = endBitIndexOrNil else {
            fatalError("Expected occupancy, found none")
        }

        let mask = Chunk.mask(range: startBitIndex...endBitIndex)
        self.chunks[chunkIndex].setZeros(atMask: mask)
        self.count -= 1

        let index = Self.index(chunk: chunkIndex, bit: endBitIndex)
        let payload = Self.globalPayload

        return (index, payload)
    }

    public mutating func remove(_ index: Index) -> Payload {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        let (chunkIndex, bitIndex) = index.indices(given: Bits.self)
        let mask = Chunk.mask(index: bitIndex)
        self.chunks[chunkIndex].setZeros(atMask: mask)
        self.count -= 1

        return Self.globalPayload
    }

    public mutating func removeExpired(
        _ evictionCallback: (Index) -> Void
    ) {
        // do nothing
    }

    @inlinable
    @inline(__always)
    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

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

    private mutating func randomStartIndex() -> Index {
        let uint = UInt(truncatingIfNeeded: self.generator.next())
        let int = Int(truncatingIfNeeded: uint >> 1)
        let count = self.count
        let index = (count != 0) ? (int % count) : 0
        return .init(index)
    }

    private func logState(to logger: Logger = logger) {
        guard logger.logLevel <= .trace else {
            return
        }

        let chunks = self.chunks.lazy.map {
            $0.bits
        }.map {
            "\($0, radix: .binary, toWidth: Bits.bitWidth)"
        }.joined(separator: ", ")

        logger.trace("count: \(count)")
        logger.trace("chunks:   [\(chunks)]")
    }

    #if DEBUG
    internal func isValid() -> Bool? {
        let validCount = self.chunks.reduce(0) {
            $0 + $1.count
        } == self.count

        guard validCount else {
            return false
        }

        return true
    }
    #endif
}
