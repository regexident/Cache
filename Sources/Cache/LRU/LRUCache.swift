// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public struct LRUCache<Key, Value>
where
    Key: Hashable
{
    public typealias Element = (key: Key, value: Value)

    fileprivate typealias Queue = DoublyLinkedList<Element>
    fileprivate typealias QueueNode = Queue.Node

    /// Complexity: O(`1`).
    public var isEmpty: Bool {
        self.dictionary.isEmpty
    }

    /// Complexity: O(`1`).
    public var count: Int {
        self.dictionary.count
    }

    public var capacity: Int {
        self.dictionary.capacity
    }

    public private(set) var totalCostLimit: Int {
        didSet {
            assert(self.totalCostLimit >= 0)

            self.removeLeastRecentlyUsed(
                Swift.max(0, self.count - self.totalCostLimit)
            )
        }
    }

    fileprivate private(set) var dictionary: [Key: QueueNode]
    fileprivate private(set) var queue: Queue

    public init(
        totalCostLimit: Int
    ) {
        assert(totalCostLimit >= 0)

        let totalCostLimit = Self.totalCostLimitFor(
            totalCostLimit: totalCostLimit
        )

        self.totalCostLimit = totalCostLimit
        self.dictionary = .init()
        self.queue = .init()
    }

    @inlinable
    @inline(__always)
    public init<S>(
        uniqueKeysWithValues keysAndValues: S
    )
    where
        S: Sequence,
        S.Element == (Key, Value)
    {
        self.init(
            totalCostLimit: .max,
            uniqueKeysWithValues: keysAndValues
        )
    }

    public init<S>(
        totalCostLimit: Int,
        uniqueKeysWithValues keysAndValues: S
    )
    where
        S: Sequence,
        S.Element == (Key, Value)
    {
        self.init(totalCostLimit: totalCostLimit)
        for (key, value) in keysAndValues {
            self.setValue(value, forKey: key)
        }
    }

    public mutating func resizeTo(
        totalCostLimit: Int
    ) {
        let totalCostLimit = Self.totalCostLimitFor(
            totalCostLimit: totalCostLimit
        )
        self.totalCostLimit = totalCostLimit
    }

    public mutating func value(
        forKey key: Key
    ) -> Value? {
        guard let node = self.node(forKey: key) else {
            return nil
        }

        return node.element.value
    }

    public func peekValue(
        forKey key: Key
    ) -> Value? {
        guard let node = self.dictionary[key] else {
            return nil
        }

        return node.element.value
    }

    public mutating func setValue(
        _ value: Value?,
        forKey key: Key
    ) {
        guard let value = value else {
            self.removeValue(forKey: key)
            return
        }

        self.updateValue(value, forKey: key)
    }

    @discardableResult
    public mutating func updateValue(
        _ value: Value,
        forKey key: Key
    ) -> Value? {
        // If value present by that key, update it:

        let updatedValue = self.updateValueIfPresent(
            value,
            forKey: key
        )

        if updatedValue != nil {
            return updatedValue
        }

        // No value present by that key, so:

        // 1. Evict excessive elements, if necessary:

        if self.count >= self.totalCostLimit {
            // Remove one more, to make space for new element:
            self.removeLeastRecentlyUsed(
                Swift.max(0, self.count - (self.totalCostLimit - 1))
            )
        }

        // 2. Add the new value:

        self.addValueIfNotPresent(
            value,
            forKey: key
        )

        return nil
    }

    @discardableResult
    public mutating func removeValue(
        forKey key: Key
    ) -> Value? {
        guard let node = self.dictionary.removeValue(forKey: key) else {
            return nil
        }

        self.modifyQueue { queue in
            queue.remove(at: node)
        }

        return node.element.value
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.dictionary.removeAll(keepingCapacity: keepCapacity)
        self.modifyQueue { queue in
            queue.removeAll()
        }
    }

    @discardableResult
    private mutating func updateValueIfPresent(
        _ value: Value,
        forKey key: Key
    ) -> Value? {
        guard let node = self.dictionary[key] else {
            return nil
        }

        if self.queue.head !== node {
            self.modifyQueue { queue in
                queue.remove(node: node)
                queue.prepend(node: node)
            }
        }

        defer {
            node.element.value = value
        }

        return node.element.value
    }

    private mutating func addValueIfNotPresent(
        _ value: Value,
        forKey key: Key
    ) {
        guard self.dictionary[key] == nil else {
            return
        }

        let element = (key: key, value: value)
        let node = QueueNode(element: element)

        self.modifyQueue { queue in
            queue.prepend(node: node)
        }

        self.dictionary[key] = node
    }

    private mutating func removeLeastRecentlyUsed(_ k: Int) {
        for _ in 0..<k {
            self.removeLeastRecentlyUsed()
        }
    }

    @discardableResult
    private mutating func removeLeastRecentlyUsed() -> Element? {
        guard !self.isEmpty else {
            return nil
        }

        let element = self.modifyQueue { queue in
            queue.removeLast()
        }

        self.dictionary.removeValue(forKey: element.key)

        return element
    }

    private mutating func node(forKey key: Key) -> QueueNode? {
        guard let node = self.dictionary[key] else {
            return nil
        }

        self.modifyQueue { queue in
            queue.remove(node: node)
            queue.prepend(node: node)
        }

        return node
    }

    private static func totalCostLimitFor(
        totalCostLimit: Int
    ) -> Int {
        assert(totalCostLimit >= 0)

        return totalCostLimit
    }

    // Since `Queue` has reference semantics we need to guard
    // mutating access to it with `.isKnownUniquelyReferenced()`
    // to ensure conforming to value semantics:
    @discardableResult
    private mutating func modifyQueue<T>(
        closure: (inout Queue) throws -> T
    ) rethrows -> T {
        if !Swift.isKnownUniquelyReferenced(&self.queue) {
            self.queue = Queue(self.queue)
        }

        return try closure(&self.queue)
    }
}

extension LRUCache: Equatable
where
    Value: Equatable
{
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.dictionary.count == rhs.dictionary.count else {
            return false
        }

        for (key, lhsNode) in lhs.dictionary {
            guard let rhsNode = rhs.dictionary[key] else {
                return false
            }
            let lhsElement = lhsNode.element
            let rhsElement = rhsNode.element

            guard lhsElement.key == rhsElement.key else {
                return false
            }
            guard lhsElement.value == rhsElement.value else {
                return false
            }
        }

        return true
    }
}

extension LRUCache: Hashable
where
    Value: Hashable
{
    public func hash(into hasher: inout Hasher) {
        var commutativeHash = 0
        for node in self.dictionary.values {
            let (key, value) = node.element
            var elementHasher = hasher
            key.hash(into: &elementHasher)
            value.hash(into: &elementHasher)
            commutativeHash ^= elementHasher.finalize()
        }
        hasher.combine(commutativeHash)
    }
}

extension LRUCache: ExpressibleByDictionaryLiteral {
    @inlinable
    @inline(__always)
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
}

extension LRUCache: CustomStringConvertible {
    public var description: String {
        let typeName = String(describing: type(of: self))
        let elements = self.queue.lazy.map { key, value in
            return "\(key): \(value)"
        }.joined(separator: ", ")
        return "\(typeName)(totalCostLimit: \(self.totalCostLimit), elements: [\(elements)])"
    }
}

extension LRUCache: Sequence {
    public typealias Iterator = AnyIterator<Element>

    public func makeIterator() -> Iterator {
        .init(self.queue.makeIterator())
    }
}
