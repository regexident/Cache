// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

internal struct BitChunk<Bits>
where
    Bits: FixedWidthInteger
{
    internal static var bitWidth: Int {
        Bits.bitWidth
    }

    internal static var zeros: Self {
        .init(bits: 0b0 as Bits)
    }

    internal static var ones: Self {
        .init(bits: ~0b0 as Bits)
    }

    internal var isEmpty: Bool {
        self == .zeros
    }

    internal var isFull: Bool {
        self == .ones
    }

    internal var count: Int {
        self.bits.nonzeroBitCount
    }

    internal private(set) var bits: Bits

    internal init() {
        self.init(bits: 0b0)
    }

    internal init(bits: Bits) {
        self.bits = bits
    }

    internal static func emptyRange() -> Range<Int> {
        0..<0
    }

    internal static func fullRange() -> Range<Int> {
        0..<Bits.bitWidth
    }

    internal static func emptyMask() -> Bits {
        (0b0 as Bits)
    }

    internal static func fullMask() -> Bits {
        ~(0b0 as Bits)
    }

    internal static func mask(
        index: Int
    ) -> Bits {
        (0b1 as Bits) << index
    }

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

    internal static func mask(
        range: PartialRangeFrom<Int>
    ) -> Bits {
        let offset = range.lowerBound
        let bits = self.fullMask() << offset
        return bits
    }

    internal static func mask(
        range: PartialRangeUpTo<Int>
    ) -> Bits {
        let offset = Bits.bitWidth - range.upperBound
        let bits = self.fullMask() >> offset
        return bits
    }

    internal static func mask(
        range: PartialRangeThrough<Int>
    ) -> Bits {
        let offset = Bits.bitWidth - range.upperBound - 1
        let bits = self.fullMask() >> offset
        return bits
    }

    internal mutating func setZeros(atMask mask: Bits) {
        self.bits &= ~mask
    }

    internal mutating func setOnes(atMask mask: Bits) {
        self.bits |= mask
    }

    internal func isZeros(atMask mask: Bits) -> Bool {
        (self.bits & mask) == Self.emptyMask()
    }

    internal func isOnes(atMask mask: Bits) -> Bool {
        (self.bits & mask) == mask
    }

    internal func hasZeros(atMask mask: Bits) -> Bool {
        (self.bits & mask) != mask
    }

    internal func hasOnes(atMask mask: Bits) -> Bool {
        (self.bits & mask) != Self.emptyMask()
    }

    internal func indexOfFirstZero(
        inRange range: Range<Int>
    ) -> Int? {
        Self.indexOfFirstOne(in: ~self.bits, range: range)
    }

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
