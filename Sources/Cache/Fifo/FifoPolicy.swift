// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

/// First-in, first-out cache policy.
///
/// See `CustomFifoPolicy<…>` for more info.
public typealias FifoPolicy = CustomFifoPolicy<UInt32>

/// First-in, first-out cache policy.
///
/// A simple cache eviction strategy where the oldest cache entry
/// (i.e., the one added earliest) is evicted when the cache is full.
///
/// This policy operates on the assumption that the order of insertion
/// reflects relevance over time, making it straightforward and predictable,
/// though it may not always align with actual access patterns.
public struct CustomFifoPolicy<RawIndex>: CachePolicy
where
    RawIndex: FixedWidthInteger & UnsignedInteger
{
    public typealias Index = BufferedDeque<Metadata, RawIndex>.Index
    public typealias Metadata = NoMetadata

    internal typealias Deque = BufferedDeque<Metadata, RawIndex>
    
    public var isEmpty: Bool {
        self.deque.isEmpty
    }

    public var count: Int {
        self.deque.count
    }

    internal private(set) var deque: Deque

    public init() {
        self.init(minimumCapacity: 0)
    }

    public init(minimumCapacity: Int) {
        self.deque = .init(
            minimumCapacity: minimumCapacity
        )
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
        self.deque.pushFront(element: metadata)
    }

    public mutating func use(
        _ index: Index,
        metadata: Metadata
    ) -> Index {
        return index
    }

    public mutating func remove() -> (index: Index, metadata: Metadata)? {
        guard let (index, metadata) = self.deque.popBack() else {
            return nil
        }

        return (index, metadata)
    }

    public mutating func remove(_ index: Index) -> Metadata {
        self.deque.remove(at: index)
    }

    public mutating func removeExpired(
        _ evictionCallback: (Index) -> Void
    ) {
        // do nothing
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.deque.removeAll(keepingCapacity: keepCapacity)
    }
}
