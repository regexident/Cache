// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

internal struct ClockBlock<Bits>
where
    Bits: FixedWidthInteger
{
    public typealias Chunk = BitChunk<Bits>

    @inlinable
    @inline(__always)
    internal var unoccupied: Chunk {
        let bits = ~self.occupied.bits
        return .init(bits: bits)
    }

    @inlinable
    @inline(__always)
    internal var unreferenced: Chunk {
        let bits = self.occupied.bits & ~self.referenced.bits
        return .init(bits: bits)
    }

    @inline(__always)
    internal var occupied: Chunk = .init()

    @inline(__always)
    internal var referenced: Chunk = .init()

    @inlinable
    @inline(__always)
    internal mutating func occupy(
        mask: Bits
    ) {
        self.occupied.setOnes(atMask: mask)
    }

    @inlinable
    @inline(__always)
    internal mutating func evict(
        mask: Bits
    ) {
        self.occupied.setZeros(atMask: mask)
        self.referenced.setZeros(atMask: mask)
    }

    @inlinable
    @inline(__always)
    internal mutating func reference(
        mask: Bits
    ) {
        self.referenced.setOnes(atMask: mask)
    }

    @inlinable
    @inline(__always)
    internal mutating func dereference(
        mask: Bits
    ) {
        self.referenced.setZeros(atMask: mask)
    }

    @inlinable
    @inline(__always)
    internal mutating func isOccupied(
        mask: Bits
    ) -> Bool {
        self.occupied.isOnes(atMask: mask)
    }

    @inlinable
    @inline(__always)
    internal mutating func isVacant(
        mask: Bits
    ) -> Bool {
        guard self.occupied.isZeros(atMask: mask) else {
            return false
        }
        guard self.referenced.isZeros(atMask: mask) else {
            return false
        }
        return true
    }

    @inlinable
    @inline(__always)
    internal mutating func isReferenced(
        mask: Bits
    ) -> Bool {
        self.referenced.isOnes(atMask: mask)
    }

    @inlinable
    @inline(__always)
    internal mutating func isUnreferenced(
        mask: Bits
    ) -> Bool {
        self.unreferenced.isOnes(atMask: mask)
    }

    @inlinable
    @inline(__always)
    internal func indexOfFirstUnnoccupied(
        range: Range<Int>
    ) -> Int? {
        let bits = self.unoccupied
        guard !bits.isEmpty else {
            return nil
        }
        return bits.indexOfFirstOne(inRange: range)
    }

    @inlinable
    @inline(__always)
    internal func indexOfFirstUnreferenced(
        range: Range<Int>
    ) -> Int? {
        let bits = self.unreferenced
        guard !bits.isEmpty else {
            return nil
        }
        return bits.indexOfFirstOne(inRange: range)
    }

    #if DEBUG
    internal func isValid() -> Bool? {
        guard shouldValidate else {
            return nil
        }

        let occupied = self.occupied.bits
        let referenced = self.referenced.bits

        guard (occupied | referenced) == occupied else {
            return false
        }

        return true
    }
    #endif
}
