// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Logging

public struct CapacityPolicy<Base>: CachePolicy
where
    Base: CachePolicy
{
    public typealias Index = Base.Index
    public typealias Payload = Base.Payload

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

    public mutating func evictIfNeeded(
        for trigger: CacheEvictionTrigger<Payload>,
        callback: (Index) -> Void
    ) {
        self.base.evictIfNeeded(
            for: trigger,
            callback: callback
        )

        let maxCount: Int
        switch trigger {
        case .alloc:
            maxCount = max(0, self.maximumCapacity - 1)
        case .trace:
            maxCount = self.maximumCapacity
        }

        while self.count > maxCount {
            guard let (index, _) = self.base.remove() else {
                break
            }

            callback(index)
        }
    }

    public mutating func insert(payload: Payload) -> Index {
        // Evict excessive elements, if necessary:

        if self.count >= self.maximumCapacity {
            // Remove one or more, to make space for new element:

            guard let _ = self.remove() else {
                fatalError("Expected `index`, found `nil`")
            }
        }

        return self.base.insert(payload: payload)
    }

    public mutating func use(_ index: Index) {
        self.base.use(index)
    }

    public mutating func remove() -> (index: Index, payload: Payload)? {
        self.base.remove()
    }

    public mutating func remove(_ index: Index) -> Payload {
        self.base.remove(index)
    }

    public mutating func removeAll() {
        self.base.removeAll()
    }

    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        self.base.removeAll(keepingCapacity: keepCapacity)
    }
}
