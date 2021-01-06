import Foundation

/// A generator that returns a looping monotonically incrementing bounded sequence of integer values.
public struct RepeatingRangeKeyGenerator: IteratorProtocol {
    public typealias Element = Int

    public let range: Range<Element>
    public var index: Int

    public init(
        range: Range<Element>
    ) {
        self.range = range
        self.index = 0
    }

    public mutating func next() -> Element? {
        defer {
            self.index += 1
        }

        let index = self.index % self.range.count
        let element = self.range[index]

        return element
    }
}
