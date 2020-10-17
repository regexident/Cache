// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

internal class LRUQueue {
    internal class Node: Equatable {
        internal var next: Node?
        internal weak var previous: Node?

        internal init(
            next: Node? = nil,
            previous: Node? = nil
        ) {
            self.next = next
            self.previous = previous
        }

        internal static func == (
            lhs: Node,
            rhs: Node
        ) -> Bool {
            ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
        }
    }

    internal private(set) var head: Node?
    internal private(set) var tail: Node?

    internal init() {
        self.head = nil
        self.tail = nil
    }

    internal func enqueue() -> Node {
        let node = Node()
        self.enqueue(node)
        return node
    }

    internal func enqueue(_ node: Node) {
        assert(node.previous == nil)
        assert(node.next == nil)

        guard self.head != nil else {
            self.head = node
            self.tail = node

            return
        }

        node.previous = nil

        let currentHead = self.head

        self.head?.previous = node
        self.head = node
        self.head?.next = currentHead
    }

    internal func dequeue(_ node: Node) {
        if self.head === node {
            self.head = node.next
        }
        if self.tail === node {
            self.tail = node.previous
        }

        if let previousNode = node.previous {
            previousNode.next = node.next
        }
        if let nextNode = node.next {
            nextNode.previous = node.previous
        }

        node.next = nil
        node.previous = nil
    }

    @discardableResult
    internal func dequeueLeastRecentlyUsed() -> Node {
        guard let tail = self.tail else {
            fatalError(
                "Can't remove last node from an empty queue"
            )
        }

        self.dequeue(tail)

        return tail
    }

    internal func dequeueAll() {
        self.head = nil
        self.tail = nil
    }

    internal func requeue(_ node: Node) {
        self.dequeue(node)
        self.enqueue(node)
    }
}
