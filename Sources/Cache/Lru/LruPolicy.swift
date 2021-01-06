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

public typealias LruPayload = NoPayload

public typealias LruPolicy = CustomLruPolicy<UInt32>;

public struct CustomLruPolicy<RawIndex>: CachePolicy
where
    RawIndex: BinaryInteger
{
    public typealias Index = LruIndex<RawIndex>
    public typealias Payload = LruPayload
    internal typealias Node = LruNode<RawIndex>

    // Since there is only a single possible instance
    // of `Payload` (aka `NoPayload`) we
    // access it via `Self.globalPayload` to make
    // things more explicit.
    private static var globalPayload: Payload {
        .default
    }
    
    public var isEmpty: Bool {
        self.count == 0
    }

    public private(set) var count: Int

    public var capacity: Int {
        self.nodes.capacity
    }

    internal private(set) var head: RawIndex?
    internal private(set) var tail: RawIndex?
    internal private(set) var nodes: [Node]
    internal private(set) var firstFree: RawIndex?

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
        assert(minimumCapacity >= 0)

        // Next smallest greater than or equal power of 2:
        let capacity: Int

        if minimumCapacity > 0 {
            let leadingZeros = minimumCapacity.leadingZeroBitCount
            capacity = 0b1 << (Int.bitWidth - leadingZeros)
        } else {
            capacity = 0
        }

        self.init(
            head: nil,
            tail: nil,
            nodes: (0..<capacity).map { index in
                let nextIndex = index + 1
                let nextFree: RawIndex?
                if nextIndex < capacity {
                    nextFree = .init(nextIndex)
                } else {
                    nextFree = nil
                }
                return .free(.init(nextFree: nextFree))
            },
            firstFree: (capacity > 0) ? .init(0) : nil,
            count: 0
        )
    }

    internal init(
        head: RawIndex?,
        tail: RawIndex?,
        nodes: [Node],
        firstFree: RawIndex?,
        count: Int
    ) {
        self.head = head
        self.tail = tail
        self.nodes = nodes
        self.firstFree = firstFree
        self.count = count
    }

    public mutating func evictIfNeeded(
        for trigger: CacheEvictionTrigger<Payload>,
        callback: (Index) -> Void
    ) {
        // nothing
    }

    public mutating func insert(payload: Payload) -> Index {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        if self.firstFree == nil {
            self.firstFree = .init(self.nodes.count)
            self.nodes.append(.free(.init(nextFree: nil)))
        }

        let index = self.firstFree!
        let currentHead = self.head

        let free: RawIndex? = self.modifyNode(at: index) { node in
            guard case .free(let free) = node else {
                fatalError("Expected free lot, found occupied.")
            }

            node = .occupied(.init(
                previous: nil,
                next: currentHead
            ))

            return free.nextFree
        }

        if let head = currentHead {
            self.modifyOccupiedNode(at: head) { occupied in
                occupied.previous = index
            }
        } else {
            self.tail = index
        }

        self.head = index
        self.firstFree = free
        self.count += 1

        return .init(index)
    }

    public mutating func use(_ index: Index) {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        guard self.head != index.value else {
            return
        }

        let payload = self.remove(index)

        let insertedIndex = self.insert(payload: payload)

        assert(insertedIndex == index)
    }

    public mutating func remove() -> (index: Index, payload: Payload)? {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        guard let rawIndex = self.tail else {
            return nil
        }

        let index = Index(rawIndex)
        let payload = self.remove(index)

        return (index, payload)
    }

    public mutating func remove(_ index: Index) -> Payload {
        #if DEBUG
        logger.trace("\(type(of: self)).\(#function)")
        self.logState(to: logger)

        defer {
            self.logState(to: logger)
            logger.trace("")

            assert(self.isValid() != false)
        }
        #endif

        let rawIndex = index.value

        let nodeOrNil: Node.Occupied? = self.modifyNode(at: rawIndex) { node in
            switch node {
            case .free(_):
                return nil
            case .occupied(let occupied):
                node = .occupied(.init())
                return occupied
            }
        }

        let payload = Self.globalPayload

        guard let node = nodeOrNil else {
            return payload
        }

        if self.head == index.value {
            self.head = node.next
        }

        if self.tail == index.value {
            self.tail = node.previous
        }

        if let previousIndex = node.previous {
            self.modifyOccupiedNode(at: previousIndex) { occupied in
                assert(occupied.next == rawIndex)
                occupied.next = node.next
            }
        }
        if let nextIndex = node.next {
            self.modifyOccupiedNode(at: nextIndex) { occupied in
                assert(occupied.previous == rawIndex)
                occupied.previous = node.previous
            }
        }

        self.nodes[Int(rawIndex)] = .free(.init(nextFree: self.firstFree))
        self.firstFree = rawIndex
        self.count -= 1

        return payload
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

        self.head = nil
        self.tail = nil

        self.nodes.removeAll(keepingCapacity: keepCapacity)
        self.firstFree = nil
        self.count = 0
    }

    private mutating func modifyOccupiedNode<T>(
        at index: RawIndex,
        _ closure: (inout Node.Occupied) -> T
    ) -> T {
        self.modifyNode(at: index) { node in
            guard case .occupied(var occupied) = node else {
                fatalError("Expected occupied lot, found free.")
            }

            defer {
                node = .occupied(occupied)
            }

            return closure(&occupied)
        }
    }

    private mutating func modifyNode<T>(
        at index: RawIndex,
        _ closure: (inout Node) -> T
    ) -> T {
        self.nodes.modifyElement(at: Int(index)) { node in
            return closure(&node)
        }
    }

    private func logState(to logger: Logger = logger) {
        guard logger.logLevel <= .trace else {
            return
        }

        let count = self.count
        let head = self.head.map { String(describing: $0) } ?? "nil"
        let tail = self.tail.map { String(describing: $0) } ?? "nil"

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

        var currentIndex: RawIndex? = self.head
        var previousIndex: RawIndex? = nil

        // Walk linked list:

        while let rawIndex = currentIndex {
            let index = Int(rawIndex)

            let node = self.nodes[index]
            guard case .occupied(let occupied) = node else {
                return false
            }

            visitedOccupied.insert(.init(rawIndex))

            if currentIndex == self.head {
                // No node before head:
                guard occupied.previous == nil else {
                    return false
                }
            } else if currentIndex == self.tail {
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

        currentIndex = self.firstFree

        while let rawIndex = currentIndex {
            let index = Int(rawIndex)

            let node = self.nodes[index]
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

        guard visited.count == self.nodes.count else {
            return false
        }

        return true
    }
    #endif
}
