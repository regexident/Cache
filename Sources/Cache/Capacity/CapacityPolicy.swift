// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Logging

public struct CapacityPolicy<Base>: CachePolicy
where
    Base: CachePolicy
{
    public typealias Index = Base.Index
    public typealias Metadata = Base.Metadata

    public var isEmpty: Bool {
        self.base.isEmpty
    }

    public var count: Int {
        self.base.count
    }

    public var maximumCapacity: Int {
        didSet {
            assert(self.maximumCapacity >= 0)
        }
    }

    private var base: Base

    public init(
        base: Base,
        maximumCapacity: Int
    ) {
        self.base = base
        self.maximumCapacity = maximumCapacity
    }

    public func hasCapacity(
        forMetadata metadata: Metadata?
    ) -> Bool {
        let requiredCapacity: Int

        switch metadata {
        case .some:
            requiredCapacity = self.count + 1
        case .none:
            requiredCapacity = self.count
        }

        return requiredCapacity <= self.maximumCapacity
    }

    public func state(of index: Index) -> CachePolicyIndexState {
        self.base.state(of: index)
    }

    public mutating func insert(metadata: Metadata) -> Index {
        // Evict excessive elements, if necessary:

        if self.count >= self.maximumCapacity {
            // Remove one or more, to make space for new element:

            guard let _ = self.remove() else {
                fatalError("Expected `index`, found `nil`")
            }
        }

        return self.base.insert(metadata: metadata)
    }

    public mutating func use(
        _ index: Index,
        metadata: Metadata
    ) -> Index {
        self.base.use(index, metadata: metadata)
    }

    public mutating func remove() -> (index: Index, metadata: Metadata)? {
        self.base.remove()
    }

    public mutating func remove(_ index: Index) -> Metadata {
        self.base.remove(index)
    }

    public mutating func removeExpired(
        _ evictionCallback: (Index) -> Void
    ) {
        self.base.removeExpired(evictionCallback)
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.base.removeAll(keepingCapacity: keepCapacity)
    }
}
