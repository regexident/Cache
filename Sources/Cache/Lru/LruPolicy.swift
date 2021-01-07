// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Logging

public typealias LruCache<Key, Value> = CustomLruCache<Key, Value, Int>
where
    Key: Hashable

public typealias CustomLruCache<Key, Value, Index> = CustomCache<Key, Value, CustomLruPolicy<Index>>
where
    Key: Hashable,
    Index: BinaryInteger

public typealias LruPolicy = CustomLruPolicy<UInt32>;

public struct CustomLruPolicy<RawIndex>: CachePolicy
where
    RawIndex: BinaryInteger
{
    public typealias Index = BufferedDeque<Metadata, RawIndex>.Index
    public typealias Metadata = NoMetadata

    internal typealias Deque = BufferedDeque<Metadata, RawIndex>
    internal typealias Node = Deque.Node

    public var isEmpty: Bool {
        self.count == 0
    }

    public var count: Int {
        self.deque.count
    }

    public var capacity: Int {
        self.deque.capacity
    }

    internal private(set) var deque: Deque

    /// Creates an empty cache policy with no preallocated space.
    public init() {
        self.init(minimumCapacity: 0)
    }

    /// Creates an empty cache policy with preallocated space
    /// for at least the specified number of elements.
    ///
    /// - Note:
    ///   For performance reasons, the size of the newly allocated
    ///   storage might be greater than the requested capacity.
    ///   Use the policy's `capacity` property to determine the size
    ///   of the new storage.
    ///
    /// - Parameters:
    ///   - minimumCapacity:
    ///     The requested number of elements to store.
    public init(minimumCapacity: Int = 0) {
        self.deque = .init(minimumCapacity: minimumCapacity)
    }

    public func hasCapacity(
        forMetadata metadata: Metadata?
    ) -> Bool {
        true
    }

    public func state(of index: Index) -> CachePolicyIndexState {
        .alive
    }

    public mutating func insert(metadata: Metadata) -> Index {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        return self.deque.pushFront(element: metadata)
    }

    public mutating func use(
        _ index: Index,
        metadata: Metadata
    ) -> Index {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        self.deque.moveToFront(index)

        return index
    }

    public mutating func remove() -> (index: Index, metadata: Metadata)? {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        guard let (index, metadata) = self.deque.popBack() else {
            return nil
        }

        return (index, metadata)
    }

    public mutating func remove(_ index: Index) -> Metadata {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        return self.deque.remove(at: index)
    }

    public mutating func removeExpired(
        _ evictionCallback: (Index) -> Void
    ) {
        // do nothing
    }

    @inlinable
    @inline(__always)
    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        return self.deque.removeAll(keepingCapacity: keepCapacity)
    }

    private func logState(to logger: Logger = logger) {
        guard logger.logLevel <= .trace else {
            return
        }

        let count = self.deque.count
        let head = self.deque.head.map { String(describing: $0) } ?? "nil"
        let tail = self.deque.tail.map { String(describing: $0) } ?? "nil"

        logger.trace("count: \(count)")
        logger.trace("head: \(head)")
        logger.trace("tail: \(tail)")
    }

    #if DEBUG
    internal func isValid() -> Bool? {
        guard shouldValidate else {
            return nil
        }

        var visitedFree: Set<Index> = []
        var visitedOccupied: Set<Index> = []

        var currentIndex: RawIndex? = self.deque.head
        var previousIndex: RawIndex? = nil

        // Walk linked list:

        while let rawIndex = currentIndex {
            let index = Int(rawIndex)

            let node = self.deque.nodes[index]
            guard case .occupied(let occupied) = node else {
                return false
            }

            visitedOccupied.insert(.init(rawIndex))

            if currentIndex == self.deque.head {
                // No node before head:
                guard occupied.previous == nil else {
                    return false
                }
            } else if currentIndex == self.deque.tail {
                // No node after tail:
                guard occupied.next == nil else {
                    return false
                }
            }

            // Proper bi-directional links:
            guard occupied.previous == previousIndex else {
                return false
            }

            previousIndex = currentIndex
            currentIndex = occupied.next
        }

        // Walk free list:

        currentIndex = self.deque.firstFree

        while let rawIndex = currentIndex {
            let index = Int(rawIndex)

            let node = self.deque.nodes[index]
            guard case .free(let free) = node else {
                return false
            }

            visitedFree.insert(.init(rawIndex))

            previousIndex = currentIndex
            currentIndex = free.nextFree
        }

        guard visitedOccupied.count == self.count else {
            return false
        }

        let visited = visitedFree.union(visitedOccupied)

        guard visited.count == self.deque.nodes.count else {
            return false
        }

        return true
    }
    #endif
}
