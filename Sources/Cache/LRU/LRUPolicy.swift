// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public typealias LRUCache<Key, Value> = Cache<Key, Value, Int, LRUPolicy>
where
    Key: Hashable

public struct LRUToken {
    fileprivate let index: LRUQueue.Index

    fileprivate init(_ index: LRUQueue.Index) {
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

    private typealias Node = LRUQueue.Node
    private typealias queue = LRUQueue

    private var queue: queue

    public init() {
        self.init(minimumCapacity: 0)
    }

    public init(minimumCapacity: Int) {
        self.queue = .init(minimumCapacity: minimumCapacity)
    }

    public mutating func insert() -> Token {
        let index = self.queue.enqueue()
        return .init(index)
    }

    public mutating func use(_ token: Token) {
        let index = token.index
        self.queue.requeue(index)
    }

    public mutating func next() -> Token? {
        guard let index = self.queue.next() else {
            return nil
        }
        return .init(index)
    }

    public mutating func remove(_ token: Token) {
        let index = token.index
        self.queue.dequeue(index)
    }

    @inlinable
    @inline(__always)
    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.queue.dequeueAll(
            keepingCapacity: keepCapacity
        )
    }
}
