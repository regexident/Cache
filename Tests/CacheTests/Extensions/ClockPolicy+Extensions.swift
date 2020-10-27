import XCTest

@testable import Cache

extension CustomClockPolicy {
    internal var occupiedBits: [Bits] {
        self.blocks.map { block in
            block.occupied.bits
        }
    }

    internal var referencedBits: [Bits] {
        self.blocks.map { block in
            block.referenced.bits
        }
    }

    internal init(
        count: Int,
        occupiedBits: [Bits],
        referencedBits: [Bits],
        insertCursor: Index,
        removeCursor: Index
    ) {
        assert(occupiedBits.count == referencedBits.count)

        let chunks = zip(occupiedBits, referencedBits)
        self.init(
            count: count,
            blocks: chunks.map {
                .init(
                    occupied: .init(bits: $0),
                    referenced: .init(bits: $1)
                )
            },
            cursors: .init(
                insert: insertCursor,
                remove: removeCursor
            )
        )
    }
}
