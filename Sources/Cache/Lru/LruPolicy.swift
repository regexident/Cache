// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public typealias LruCache<Key, Value> = CustomCache<Key, Value, Int, LruPolicy>
where
    Key: Hashable

public struct LruPolicy: CachePolicy {
    public typealias Index = LruIndex

    internal enum Node: Equatable {
        internal struct Free: Equatable {
            var nextFree: Index?
        }

        internal struct Occupied: Equatable {
            var previous: Index?
            var next: Index?
        }

        case free(Free)
        case occupied(Occupied)
    }

    public var isEmpty: Bool {
        self.count > 0
    }

    public private(set) var count: Int

    public var capacity: Int {
        self.nodes.capacity
    }

    internal private(set) var head: Index?
    internal private(set) var tail: Index?
    internal private(set) var nodes: [Node]
    internal private(set) var firstFree: Index?

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
    public init(minimumCapacity: Int) {
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
                let nextFree: Index?
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
        head: Index?,
        tail: Index?,
        nodes: [Node],
        firstFree: Index?,
        count: Int
    ) {
        self.head = head
        self.tail = tail
        self.nodes = nodes
        self.firstFree = firstFree
        self.count = count
    }

    public mutating func insert() -> Index {
        if self.firstFree == nil {
            self.firstFree = .init(self.nodes.count)
            self.nodes.append(.free(.init(nextFree: nil)))
        }

        #if DEBUG
        let countBefore = self.count
        #endif

        let index = self.firstFree!
        let currentHead = self.head

        let free: Index? = self.modifyNode(at: index) { node in
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

        #if DEBUG
        assert(self.count - 1 == countBefore)
        #endif

        return index
    }

    public mutating func use(_ index: Index) {
        guard self.head != index else {
            return
        }

        self.remove(index)

        let insertedIndex = self.insert()

        assert(insertedIndex == index)
    }

    public mutating func remove() -> Index? {
        guard let index = self.tail else {
            return nil
        }
        self.remove(index)
        return index
    }

    public mutating func remove(_ index: Index) {
        #if DEBUG
        let countBefore = self.count
        #endif

        let nodeOrNil: Node.Occupied? = self.modifyNode(at: index) { node in
            switch node {
            case .free(_):
                return nil
            case .occupied(let occupied):
                node = .occupied(.init())
                return occupied
            }
        }

        guard let node = nodeOrNil else {
            return
        }

        if self.head == index {
            self.head = node.next
        }

        if self.tail == index {
            self.tail = node.previous
        }

        if let previousIndex = node.previous {
            self.modifyOccupiedNode(at: previousIndex) { occupied in
                assert(occupied.next == index)
                occupied.next = node.next
            }
        }
        if let nextIndex = node.next {
            self.modifyOccupiedNode(at: nextIndex) { occupied in
                assert(occupied.previous == index)
                occupied.previous = node.previous
            }
        }

        self.nodes[index.value] = .free(.init(nextFree: self.firstFree))
        self.firstFree = index
        self.count -= 1

        #if DEBUG
        assert(self.count + 1 == countBefore)
        #endif
    }

    @inlinable
    @inline(__always)
    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.head = nil
        self.tail = nil

        self.nodes.removeAll(keepingCapacity: keepCapacity)
        self.firstFree = nil
        self.count = 0
    }

    private mutating func modifyOccupiedNode<T>(
        at index: Index,
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
        at index: Index,
        _ closure: (inout Node) -> T
    ) -> T {
        self.nodes.modifyElement(at: index.value) { node in
            return closure(&node)
        }
    }
}
