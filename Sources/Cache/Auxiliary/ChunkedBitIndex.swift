// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public struct ChunkedBitIndex {
    @usableFromInline
    internal typealias Indices = (chunk: Int, bit: Int)

    private var _absoluteBitIndex: UInt

    internal var absoluteBitIndex: Int {
        get {
            // Wrap-around by stripping sign bit if needed:
            .init(
                truncatingIfNeeded: self._absoluteBitIndex & .max
            )
        }
        set {
            // Wrap-around by stripping sign bit if needed:
            self._absoluteBitIndex = .init(
                truncatingIfNeeded: newValue & .max
            )
        }
    }

    @usableFromInline
    internal init() {
        self.init(absoluteBitIndex: 0)
    }

    @usableFromInline
    internal init(absoluteBitIndex: Int) {
        assert(absoluteBitIndex >= 0)

        self._absoluteBitIndex = .init(absoluteBitIndex)
    }

    @usableFromInline
    internal init<Chunk>(
        given chunkType: Chunk.Type,
        chunkIndex: Int,
        bitIndex: Int
    )
    where
        Chunk: FixedWidthInteger & UnsignedInteger
    {
        // Important:
        //
        // The arithmetic of this method, which basically implements
        // (or assists in implementing) a highly optimal equivalent
        // of `%` and its inverse, requires `Chunk.bitWidth` to be
        // a power of two to produce correct results.

        assert(Self.isPowerOfTwo(Chunk.bitWidth))

        let bitsPerBitIndex = Self.bitsPerBitIndex(given: chunkType)
        let bitIndexMask: Int = ((0b1 as Int) << bitsPerBitIndex) - 1

        let msb = Int(chunkIndex) << bitsPerBitIndex
        let lsb = Int(bitIndex) & bitIndexMask

        let absoluteBitIndex = msb | lsb
        assert(absoluteBitIndex >= 0)

        self._absoluteBitIndex = .init(absoluteBitIndex)
    }

    @usableFromInline
    internal func chunkIndex<Chunk>(
        given chunkType: Chunk.Type
    ) -> Int
    where
        Chunk: FixedWidthInteger & UnsignedInteger
    {
        // Important:
        //
        // The arithmetic of this method, which basically implements
        // (or assists in implementing) a highly optimal equivalent
        // of `%` and its inverse, requires `Chunk.bitWidth` to be
        // a power of two to produce correct results.

        assert(Self.isPowerOfTwo(Chunk.bitWidth))

        let bitsPerBitIndex = Self.bitsPerBitIndex(given: chunkType)

        return self.absoluteBitIndex >> bitsPerBitIndex
    }

    @usableFromInline
    internal func bitIndex<Chunk>(
        given chunkType: Chunk.Type
    ) -> Int
    where
        Chunk: FixedWidthInteger & UnsignedInteger
    {
        // Important:
        //
        // The arithmetic of this method, which basically implements
        // (or assists in implementing) a highly optimal equivalent
        // of `%` and its inverse, requires `Chunk.bitWidth` to be
        // a power of two to produce correct results.

        assert(Self.isPowerOfTwo(Chunk.bitWidth))

        let bitsPerBitIndex = Self.bitsPerBitIndex(given: chunkType)
        let mask: Int = ((0b1 as Int) << bitsPerBitIndex) - 1

        return self.absoluteBitIndex & mask
    }

    @usableFromInline
    internal func indices<Chunk>(
        given chunkType: Chunk.Type
    ) -> Indices
    where
        Chunk: FixedWidthInteger & UnsignedInteger
    {
        // Important:
        //
        // The arithmetic of this method, which basically implements
        // (or assists in implementing) a highly optimal equivalent
        // of `%` and its inverse, requires `Chunk.bitWidth` to be
        // a power of two to produce correct results.

        assert(Self.isPowerOfTwo(Chunk.bitWidth))

        let bitIndexMask = Self.bitIndexMask(given: chunkType)
        let bitsPerBitIndex = Int(bitIndexMask + 1)

        let chunkIndex = self.absoluteBitIndex >> bitsPerBitIndex
        let bitIndex = self.absoluteBitIndex & bitIndexMask

        return (chunk: chunkIndex, bit: bitIndex)
    }

    @usableFromInline
    internal static func bitsPerBitIndex<Chunk>(
        given chunkType: Chunk.Type
    ) -> Int
    where
        Chunk: FixedWidthInteger & UnsignedInteger
    {
        // Important:
        //
        // The arithmetic of this method, which basically implements
        // (or assists in implementing) a highly optimal equivalent
        // of `%` and its inverse, requires `Chunk.bitWidth` to be
        // a power of two to produce correct results.

        assert(self.isPowerOfTwo(Chunk.bitWidth))

        let bitIndexMask = UInt(Self.bitIndexMask(given: chunkType))
        let bitsPerBitIndex = bitIndexMask.nonzeroBitCount
        return bitsPerBitIndex
    }

    @usableFromInline
    internal static func bitIndexMask<Chunk>(
        given chunkType: Chunk.Type
    ) -> Int
    where
        Chunk: FixedWidthInteger & UnsignedInteger
    {
        // Important:
        //
        // The arithmetic of this method, which basically implements
        // (or assists in implementing) a highly optimal equivalent
        // of `%` and its inverse, requires `Chunk.bitWidth` to be
        // a power of two to produce correct results.

        assert(self.isPowerOfTwo(Chunk.bitWidth))

        let bitIndexMask = Chunk.bitWidth - 1
        return bitIndexMask
    }

    private static func isPowerOfTwo(_ number: Int) -> Bool {
        (number != 0b0) && ((number & (number - 1)) == 0b0)
    }
}

extension ChunkedBitIndex: Equatable {
    public static func == (
        lhs: Self,
        rhs: Self
    ) -> Bool {
        lhs.absoluteBitIndex == rhs.absoluteBitIndex
    }
}

extension ChunkedBitIndex: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.absoluteBitIndex.hash(into: &hasher)
    }
}

extension ChunkedBitIndex: CustomStringConvertible {
    public var description: String {
        String(describing: self.absoluteBitIndex)
    }
}
