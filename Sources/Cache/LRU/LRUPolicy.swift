// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public typealias LRUCache<Key, Value> = Cache<Key, Value, Int, LRUPolicy>
where
    Key: Hashable

public struct LRUToken {
    fileprivate let node: LRUQueue.Node

    fileprivate init(node: LRUQueue.Node) {
        self.node = node
    }
}

extension LRUToken: Equatable {
    public static func == (
        lhs: LRUToken,
        rhs: LRUToken
    ) -> Bool {
        ObjectIdentifier(lhs.node) == ObjectIdentifier(rhs.node)
    }
}

extension LRUToken: Hashable {
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(self.node).hash(into: &hasher)
    }
}

public struct LRUPolicy: CachePolicy {
    public typealias Token = LRUToken

    private typealias Node = LRUQueue.Node
    private typealias queue = LRUQueue

    private let queue: queue

    public init() {
        self.queue = .init()
    }

    public mutating func insert() -> Token {
        let node = self.queue.enqueue()
        return .init(node: node)
    }

    public mutating func use(_ token: Token) {
        let node = token.node
        self.queue.dequeue(node)
        self.queue.enqueue(node)
    }

    public mutating func remove() -> Token? {
        guard let node = self.queue.tail else {
            return nil
        }

        defer {
            self.queue.dequeueLeastRecentlyUsed()
        }

        return .init(node: node)
    }

    public mutating func remove(_ token: Token) {
        self.queue.dequeue(token.node)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.queue.dequeueAll()
    }
}
