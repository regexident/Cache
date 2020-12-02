// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

internal struct BitChunk<Bits>
where
    Bits: FixedWidthInteger
{
    @inlinable
    @inline(__always)
    internal static var bitWidth: Int {
        Bits.bitWidth
    }

    @inlinable
    @inline(__always)
    internal static var zeros: Self {
        .init(bits: 0b0 as Bits)
    }

    @inlinable
    @inline(__always)
    internal static var ones: Self {
        .init(bits: ~0b0 as Bits)
    }

    @inlinable
    @inline(__always)
    internal var isEmpty: Bool {
        self == .zeros
    }

    @inlinable
    @inline(__always)
    internal var isFull: Bool {
        self == .ones
    }

    @inlinable
    @inline(__always)
    internal var count: Int {
        self.bits.nonzeroBitCount
    }

    @usableFromInline
    @inline(__always)
    internal private(set) var bits: Bits

    @inlinable
    @inline(__always)
    internal init() {
        self.init(bits: 0b0)
    }

    @inlinable
    @inline(__always)
    internal init(bits: Bits) {
        self.bits = bits
    }

    @inlinable
    @inline(__always)
    internal static func emptyRange() -> Range<Int> {
        0..<0
    }

    @inlinable
    @inline(__always)
    internal static func fullRange() -> Range<Int> {
        0..<Bits.bitWidth
    }

    @inlinable
    @inline(__always)
    internal static func emptyMask() -> Bits {
        (0b0 as Bits)
    }

    @inlinable
    @inline(__always)
    internal static func fullMask() -> Bits {
        ~(0b0 as Bits)
    }

    @inlinable
    @inline(__always)
    internal static func mask(
        index: Int
    ) -> Bits {
        assert(index < Bits.bitWidth)
        return (0b1 as Bits) &<< index
    }

    @inlinable
    @inline(__always)
    internal static func mask(
        range: Range<Int>
    ) -> Bits {
        guard range != 0..<Bits.bitWidth else {
            return self.fullMask()
        }
        let suffix = self.mask(range: range.lowerBound...)
        let prefix = self.mask(range: ..<range.upperBound)
        let bits = prefix & suffix
        return bits
    }

    @inlinable
    @inline(__always)
    internal static func mask(
        range: ClosedRange<Int>
    ) -> Bits {
        guard range != 0...Bits.bitWidth else {
            return self.fullMask()
        }
        let suffix = self.mask(range: range.lowerBound...)
        let prefix = self.mask(range: ...range.upperBound)
        let bits = prefix & suffix
        return bits
    }

    @inlinable
    @inline(__always)
    internal static func mask(
        range: PartialRangeFrom<Int>
    ) -> Bits {
        let offset = range.lowerBound
        assert(offset < Bits.bitWidth)
        let bits = self.fullMask() &<< offset
        return bits
    }

    @inlinable
    @inline(__always)
    internal static func mask(
        range: PartialRangeUpTo<Int>
    ) -> Bits {
        let offset = Bits.bitWidth - range.upperBound
        assert(offset < Bits.bitWidth)
        let bits = self.fullMask() &>> offset
        return bits
    }

    @inlinable
    @inline(__always)
    internal static func mask(
        range: PartialRangeThrough<Int>
    ) -> Bits {
        let offset = Bits.bitWidth - range.upperBound - 1
        let bits = self.fullMask() >> offset
        return bits
    }

    @inlinable
    @inline(__always)
    internal mutating func setZeros(atMask mask: Bits) {
        self.bits &= ~mask
    }

    @inlinable
    @inline(__always)
    internal mutating func setOnes(atMask mask: Bits) {
        self.bits |= mask
    }

    @inlinable
    @inline(__always)
    internal func isZeros(atMask mask: Bits) -> Bool {
        (self.bits & mask) == Self.emptyMask()
    }

    @inlinable
    @inline(__always)
    internal func isOnes(atMask mask: Bits) -> Bool {
        (self.bits & mask) == mask
    }

    @inlinable
    @inline(__always)
    internal func hasZeros(atMask mask: Bits) -> Bool {
        (self.bits & mask) != mask
    }

    @inlinable
    @inline(__always)
    internal func hasOnes(atMask mask: Bits) -> Bool {
        (self.bits & mask) != Self.emptyMask()
    }

    @inlinable
    @inline(__always)
    internal func indexOfFirstZero(
        inRange range: Range<Int>
    ) -> Int? {
        Self.indexOfFirstOne(in: ~self.bits, range: range)
    }

    @inlinable
    @inline(__always)
    internal func indexOfFirstOne(
        inRange range: Range<Int>
    ) -> Int? {
        Self.indexOfFirstOne(in: self.bits, range: range)
    }

    private static func indexOfFirstOne(
        in bits: Bits,
        range: Range<Int>
    ) -> Int? {
        guard bits != Self.emptyMask() else {
            return nil
        }
        let bits = bits >> range.lowerBound
        let index = range.lowerBound + bits.trailingZeroBitCount
        guard (0..<Bits.bitWidth).contains(index) else {
            return nil
        }
        return index
    }

    private static func clamped(
        range: PartialRangeFrom<Int>
    ) -> Range<Int> {
        let lowerBound = Swift.max(
            range.lowerBound,
            0
        )
        return lowerBound..<Bits.bitWidth
    }

    private static func clamped(
        range: PartialRangeUpTo<Int>
    ) -> Range<Int> {
        let upperBound = Swift.min(
            range.upperBound,
            Bits.bitWidth
        )
        return 0..<upperBound
    }
}

extension BitChunk: Equatable {}

extension BitChunk: CustomStringConvertible
where
    Bits: BinaryInteger
{
    var description: String {
        let binary = String(self.bits, radix: 2, uppercase: false)
        let padding = String(
            repeating: "0",
            count: Bits.bitWidth - binary.count
        )
        return padding + binary
    }
}
