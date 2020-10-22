@testable import Cache

extension ChunkedBitIndex: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(absoluteBitIndex: value)
    }
}
