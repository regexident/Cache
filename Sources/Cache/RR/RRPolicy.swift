// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public typealias RRCache<Key, Value> = CustomCache<Key, Value, Int, RRPolicy>
where
    Key: Hashable

public struct RRPolicy: CachePolicy {
    public typealias Index = RRIndex

    public var isEmpty: Bool {
        self.indices.isEmpty
    }

    public var count: Int {
        self.indices.count
    }

    public var capacity: Int {
        self.indices.capacity
    }

    internal private(set) var counter: Int
    internal private(set) var indices: Set<Index>

    public init() {
        self.init(minimumCapacity: 0)
    }

    public init(minimumCapacity: Int) {
        assert(minimumCapacity >= 0)

        self.init(
            counter: 0,
            indices: .init(minimumCapacity: minimumCapacity)
        )
    }

    internal init(
        counter: Int,
        indices: Set<Index>
    ) {
        self.counter = counter
        self.indices = indices
    }

    public mutating func insert() -> Index {
        let index = Index(self.counter)

        self.counter += 1
        self.indices.insert(index)

        return index
    }

    public mutating func use(_ index: Index) {
        // ignored
    }

    public mutating func remove() -> Index? {
        guard !self.indices.isEmpty else {
            return nil
        }
        // Calling `.removeFirst()` on Swift's Set
        // should be reasonably close to random here.
        // The order of
        return self.indices.removeFirst()
    }

    public mutating func remove(_ index: Index) {
        assert(self.indices.contains(index))
        self.indices.remove(index)
    }

    @inlinable
    @inline(__always)
    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.counter = 0
        self.indices.removeAll(keepingCapacity: keepCapacity)
    }
}
