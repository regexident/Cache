import Foundation

public struct Take<Iterator>: IteratorProtocol
where
    Iterator: IteratorProtocol
{
    public typealias Element = Iterator.Element

    private var iterator: Iterator
    public private(set) var remaining: Int

    public init(from iterator: Iterator, count: Int) {
        self.iterator = iterator
        self.remaining = count
    }

    public mutating func next() -> Element? {
        guard self.remaining > 0 else {
            return nil
        }

        self.remaining -= 1

        return self.iterator.next()
    }
}
