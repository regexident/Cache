// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

internal struct LRUQueue {
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

    internal private(set) var head: Index?
    internal private(set) var tail: Index?
    internal private(set) var nodes: [Node]
    internal private(set) var free: Index?

    internal init() {
        self.init(minimumCapacity: 0)
    }

    internal init(minimumCapacity: Int) {
        assert(minimumCapacity >= 0)

        self.init(
            head: nil,
            tail: nil,
            nodes: (0..<minimumCapacity).map { index in
                let nextIndex = index + 1
                let nextFree = (nextIndex < minimumCapacity) ? nextIndex : nil
                return .free(.init(nextFree: nextFree))
            },
            free: (minimumCapacity > 0) ? 0 : nil
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
        self.free = free
    }

    internal mutating func enqueue() -> Int {
        let index: Index
        if let free = self.free {
            index = free
            self.free = self.freeNode(at: index).nextFree
        } else {
            index = self.nodes.count
            self.nodes.append(.occupied(.init()))
        }
        self.enqueue(index)
        return index
    }

    internal mutating func enqueue(_ index: Int) {
        let currentHead = self.head

        let free: Index? = self.modifyNode(at: index) { node in
            defer {
                node = .occupied(.init(
                    previous: nil,
                    next: currentHead
                ))
            }

            guard case .free(let free) = node else {
                return nil
            }
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
        self.free = free
    }

    internal mutating func next() -> Index? {
        self.tail
    }

    internal mutating func dequeue(_ index: Index) {
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

        self.nodes[index] = .free(.init(nextFree: self.free))
        self.free = index
    }

    internal mutating func dequeueAll(
        keepingCapacity keepCapacity: Bool = false
    ) {
        self.head = nil
        self.tail = nil

        self.nodes.removeAll(keepingCapacity: keepCapacity)
        self.free = nil
    }

    internal mutating func requeue(_ index: Index) {
        guard self.head != index else {
            return
        }

        self.dequeue(index)
        self.enqueue(index)
    }

    private func occupiedNode(at index: Index) -> Node.Occupied {
        let node = self.nodes[index]
        guard case .occupied(let occupied) = node else {
            fatalError("Expected occupied slot, found free.")
        }
        return occupied
    }

    private func freeNode(at index: Index) -> Node.Free {
        let node = self.nodes[index]
        guard case .free(let free) = node else {
            fatalError("Expected free slot, found occupied.")
        }
        return free
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

    private mutating func modifyFreeNode<T>(
        at index: Index,
        _ closure: (inout Node.Free) -> T
    ) -> T {
        self.modifyNode(at: index) { node in
            guard case .free(var free) = node else {
                fatalError("Expected free slot, found occupied.")
            }

            defer {
                node = .free(free)
            }

            return closure(&free)
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
