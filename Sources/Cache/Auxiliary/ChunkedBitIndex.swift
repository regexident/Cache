// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public struct ChunkedBitIndex {
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

    internal init() {
        self.init(0)
    }

    internal init(_ absoluteBitIndex: Int) {
        assert(absoluteBitIndex >= 0)

        self._absoluteBitIndex = .init(absoluteBitIndex)
    }

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

        let bitIndexMask = Chunk.bitWidth - 1
        let bitsPerBitIndex = bitIndexMask.nonzeroBitCount

        let msb = Int(chunkIndex) << bitsPerBitIndex
        let lsb = Int(bitIndex) & bitIndexMask

        let absoluteBitIndex = msb | lsb
        assert(absoluteBitIndex >= 0)

        self._absoluteBitIndex = .init(absoluteBitIndex)
    }

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

        let bitIndexMask = Chunk.bitWidth - 1
        let bitsPerBitIndex = bitIndexMask.nonzeroBitCount

        let chunkIndex = self.absoluteBitIndex >> bitsPerBitIndex
        let bitIndex = self.absoluteBitIndex & bitIndexMask

        return (chunk: chunkIndex, bit: bitIndex)
    }

    internal func advanced(by distance: Int) -> Self {
        var result = self
        result.advance(by: distance)
        return result
    }

    internal mutating func advance(by distance: Int) {
        self.absoluteBitIndex += distance
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
