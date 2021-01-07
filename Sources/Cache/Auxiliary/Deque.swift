// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Logging

internal struct BufferedDequeFreeNode<RawIndex>: Equatable
where
    RawIndex: FixedWidthInteger & UnsignedInteger
{
    var nextFree: RawIndex?
}

internal struct BufferedDequeOccupiedNode<Element, RawIndex>
where
    RawIndex: FixedWidthInteger & UnsignedInteger
{
    var element: Element
    var previous: RawIndex?
    var next: RawIndex?
}

extension BufferedDequeOccupiedNode: Equatable
where
    Element: Equatable,
    RawIndex: Equatable
{
}

internal enum BufferedDequeNode<Element, RawIndex>
where
    RawIndex: FixedWidthInteger & UnsignedInteger
{
    internal typealias Free = BufferedDequeFreeNode<RawIndex>
    internal typealias Occupied = BufferedDequeOccupiedNode<Element, RawIndex>

    case free(Free)
    case occupied(Occupied)
}

extension BufferedDequeNode: Equatable
where
    Element: Equatable,
    RawIndex: Equatable
{
}

public struct BufferedDeque<Element, RawIndex>
where
    RawIndex: FixedWidthInteger & UnsignedInteger
{
    public typealias Index = OpaqueIndex<RawIndex>
    internal typealias Node = BufferedDequeNode<Element, RawIndex>

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

    /// Creates an empty deque with preallocated space
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

    public mutating func pushFront(
        element: Element
    ) -> Index {
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
                element: element,
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

    public mutating func moveToFront(_ index: Index) {
        guard self.head != index.rawValue else {
            return
        }

        let element = self.remove(at: index)

        let insertedIndex = self.pushFront(element: element)

        assert(insertedIndex == index)
    }

    public mutating func popBack() -> (index: Index, element: Element)? {
        guard let rawIndex = self.tail else {
            return nil
        }

        let index = Index(rawIndex)
        let element = self.remove(at: index)

        return (index, element)
    }

    public mutating func remove(at index: Index) -> Element {
        let rawIndex = index.rawValue

        let nodeOrNil: Node.Occupied? = self.modifyNode(at: rawIndex) { node in
            switch node {
            case .free(_):
                return nil
            case .occupied(let occupied):
                // FIXME: what is this line for?
                node = .occupied(.init(element: occupied.element))
                return occupied
            }
        }

        guard let node = nodeOrNil else {
            fatalError("Expected node, found nil")
        }

        if self.head == index.rawValue {
            self.head = node.next
        }

        if self.tail == index.rawValue {
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

        return node.element
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
}
