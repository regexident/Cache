// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public typealias LRUCache<Key, Value> = Cache<Key, Value, Int, LRUPolicy>
where
    Key: Hashable

public struct LRUToken {
    internal let index: LRUPolicy.Index

    internal init(index: LRUPolicy.Index) {
        self.index = index
    }
}

extension LRUToken: Equatable {
    public static func == (
        lhs: LRUToken,
        rhs: LRUToken
    ) -> Bool {
        lhs.index == rhs.index
    }
}

extension LRUToken: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.index.hash(into: &hasher)
    }
}

public struct LRUPolicy: CachePolicy {
    public typealias Token = LRUToken

    internal typealias Index = Int

    internal enum Node: Equatable {
        internal struct Free: Equatable {
            var nextFree: Int?
        }

        internal struct Occupied: Equatable {
            var previous: Index?
            var next: Index?
        }

        case free(Free)
        case occupied(Occupied)
    }

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
                let nextFree = (nextIndex < capacity) ? nextIndex : nil
                return .free(.init(nextFree: nextFree))
            },
            free: (capacity > 0) ? 0 : nil
        )
    }

    internal init(
        head: Index?,
        tail: Index?,
        nodes: [Node],
        free: Index?
    ) {
        self.head = head
        self.tail = tail
        self.nodes = nodes
        self.firstFree = free
    }

    public mutating func insert() -> Token {
        if self.firstFree == nil {
            self.firstFree = self.nodes.count
            self.nodes.append(.free(.init(nextFree: nil)))
        }

        let index = self.firstFree!
        let currentHead = self.head

        let free: Index? = self.modifyNode(at: index) { node in
            guard case .free(let free) = node else {
                fatalError("Expected free slot, found occupied.")
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

        return .init(index: index)
    }

    public mutating func use(_ token: Token) -> Token {
        guard self.head != token.index else {
            return token
        }

        self.remove(token)

        return self.insert()
    }

    public mutating func next() -> Token? {
        guard let index = self.tail else {
            return nil
        }
        return .init(index: index)
    }

    public mutating func remove(_ token: Token) {
        let index = token.index

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

        self.nodes[index] = .free(.init(nextFree: self.firstFree))
        self.firstFree = index
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
    }

    private mutating func modifyOccupiedNode<T>(
        at index: Index,
        _ closure: (inout Node.Occupied) -> T
    ) -> T {
        self.modifyNode(at: index) { node in
            guard case .occupied(var occupied) = node else {
                fatalError("Expected occupied slot, found free.")
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
        self.nodes.modifyElement(at: index) { node in
            return closure(&node)
        }
    }
}
