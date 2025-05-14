import XCTest

@testable import Cache

extension CustomRrPolicy {
    internal var chunkBits: [Bits] {
        self.chunks.map { chunk in
            chunk.bits
        }
    }

    internal init(
        count: Int,
        chunkBits: [Bits],
        generator: Generator
    ) {
        self.init(
            count: count,
            chunks: chunkBits.map { .init(bits: $0) },
            generator: generator
        )
    }
}
