// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

internal struct BitChunk<Bits>
where
    Bits: BinaryInteger & FixedWidthInteger
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

    fileprivate static var range: Range<Int> {
        0..<self.bitWidth
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

    internal static func mask(
        index: Int
    ) -> Self {
        .init(bits: (0b1 as Bits) << index)
    }

    internal static func mask(
        range: Range<Int>
    ) -> Self {
        let suffix = self.mask(range: range.lowerBound...)
        let prefix = self.mask(range: ..<range.upperBound)
        return .init(bits: prefix.bits & suffix.bits)
    }

    internal static func mask(
        range: PartialRangeFrom<Int>
    ) -> Self {
        let offset = range.lowerBound
        let bits = ~(0b0 as Bits) << offset
        return .init(bits: bits)
    }

    internal static func mask(
        range: PartialRangeUpTo<Int>
    ) -> Self {
        let offset = Bits.bitWidth - range.upperBound
        let bits = ~(0b0 as Bits) >> offset
        return .init(bits: bits)
    }

    internal static func mask(
        range: PartialRangeThrough<Int>
    ) -> Self {
        let offset = Bits.bitWidth - range.upperBound - 1
        let bits = ~(0b0 as Bits) >> offset
        return .init(bits: bits)
    }

    internal mutating func setZeros(atMask mask: Bits) {
        self.bits &= ~mask
    }

    internal mutating func setOnes(atMask mask: Bits) {
        self.bits |= mask
    }

    internal func isZeros(atMask mask: Bits) -> Bool {
        (self.bits & mask) == (0b0 as Bits)
    }

    internal func isOnes(atMask mask: Bits) -> Bool {
        (self.bits & mask) == mask
    }

    internal func hasZeros(atMask mask: Bits) -> Bool {
        (self.bits & mask) != mask
    }

    internal func hasOnes(atMask mask: Bits) -> Bool {
        (self.bits & mask) != (0b0 as Bits)
    }

    internal func indexOfFirstOne(
        inRange range: PartialRangeFrom<Int>
    ) -> Int? {
        self.indexOfFirstOne(
            inRange: Self.clamped(range: range)
        )
    }

    internal func indexOfFirstOne(
        inRange range: Range<Int>
    ) -> Int? {
        let bits = self.bits >> range.lowerBound
        let index = range.lowerBound + bits.trailingZeroBitCount
        guard Self.range.contains(index) else {
            return nil
        }
        return index
    }

    private static func clamped(
        range: PartialRangeFrom<Int>
    ) -> Range<Int> {
        let chunkRange = Self.range
        let lowerBound = Swift.max(
            range.lowerBound,
            chunkRange.lowerBound
        )
        return lowerBound..<chunkRange.upperBound
    }

    private static func clamped(
        range: PartialRangeUpTo<Int>
    ) -> Range<Int> {
        let chunkRange = Self.range
        let upperBound = Swift.min(
            range.upperBound,
            chunkRange.upperBound
        )
        return chunkRange.lowerBound..<upperBound
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
