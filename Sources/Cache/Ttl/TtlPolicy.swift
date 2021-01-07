// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public typealias TtlPolicy = CustomTtlPolicy<UInt32>

public struct CustomTtlPolicy<RawIndex>: CachePolicy
where
    RawIndex: FixedWidthInteger & UnsignedInteger
{
    public typealias Index = OpaqueIndex<RawIndex>
    public typealias Metadata = TimeInterval

    internal typealias Deque = BufferedDeque<Metadata, RawIndex>

    public var isFull: Bool {
        false
    }

    public var isEmpty: Bool {
        self.deadlinesByIndex.isEmpty
    }

    public var count: Int {
        self.deadlinesByIndex.count
    }

    internal private(set) var referenceDate: Date
    internal private(set) var deadlinesByIndex: [Index: Metadata]
    internal private(set) var free: [Index]
    internal private(set) var dateProvider: () -> Date

    public init() {
        self.init(minimumCapacity: 0)
    }

    public init(
        minimumCapacity: Int
    ) {
        self.init(
            minimumCapacity: minimumCapacity,
            dateProvider: { .init() }
        )
    }

    public init(
        minimumCapacity: Int,
        dateProvider: @escaping () -> Date
    ) {
        self.referenceDate = dateProvider()
        self.deadlinesByIndex = .init(
            minimumCapacity: minimumCapacity
        )
        self.free = []
        self.dateProvider = dateProvider
    }

    @inlinable
    @inline(__always)
    public func hasCapacity(
        forMetadata metadata: TimeInterval?
    ) -> Bool {
        true
    }

    public func state(of index: Index) -> CachePolicyIndexState {
        let timeElapsed = self.timeIntervalSinceReferenceDate()

        return self.state(of: index, at: timeElapsed)
    }

    public mutating func removeExpired(
        _ evictionCallback: (Index) -> Void
    ) {
        let timeElapsed = self.timeIntervalSinceReferenceDate()

        for index in self.deadlinesByIndex.keys {
            switch self.state(of: index, at: timeElapsed) {
            case .alive:
                continue
            case .expired:
                let _ = self.remove(index)
                evictionCallback(index)
            }
        }
    }

    public mutating func insert(metadata: Metadata) -> Index {
        let deadline = self.deadlineFor(timeInterval: metadata)

        let index = self.popNextFree()

        self.deadlinesByIndex[index] = deadline

        return index
    }

    public mutating func use(
        _ index: Index,
        metadata: Metadata
    ) -> Index {
        let deadline = self.deadlineFor(timeInterval: metadata)

        self.deadlinesByIndex[index] = deadline

        return index
    }

    public mutating func remove() -> (index: Index, metadata: Metadata)? {
        var iterator = self.deadlinesByIndex.makeIterator()

        guard var (index, deadline) = iterator.next() else {
            return nil
        }

        let timeElapsed = self.timeIntervalSinceReferenceDate()

        // Instead of first searching for an expired index
        // and if none is found search a second time for
        // the next-to-expire index we combine both searches
        // into a single exhaustive scan and break out early
        // once we encounter an expired index:

        while let (currentIndex, currentDeadline) = iterator.next() {
            // Search for the next-to-expire index:
            if currentDeadline < deadline {
                index = currentIndex
                deadline = currentDeadline
            }

            // Break out of the scan once we find an expired index:
            if currentDeadline < timeElapsed {
                break
            }
        }

        deadline = self.remove(index)

        let metadata = self.timeIntervalFor(deadline: deadline)

        return (index, metadata)
    }

    public mutating func remove(_ index: Index) -> Metadata {
        let deadlineOrNil = self.deadlinesByIndex.removeValue(forKey: index)

        self.free.append(index)

        guard let deadline = deadlineOrNil else {
            fatalError("Expected deadline, found nil")
        }

        let metadata = self.timeIntervalFor(deadline: deadline)

        return metadata
    }

    public mutating func removeAll() {
        self.removeAll(keepingCapacity: false)
    }

    public mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    ) {
        self.deadlinesByIndex.removeAll(
            keepingCapacity: keepCapacity
        )
        self.free = []
    }

    private mutating func pushNextFree(_ index: Index) {
        self.free.append(index)
    }

    private mutating func popNextFree() -> Index {
        guard !self.free.isEmpty else {
            let rawIndex = RawIndex(exactly: self.deadlinesByIndex.count)!
            return .init(rawIndex)
        }

        return self.free.removeLast()
    }

    private func state(
        of index: Index,
        at elapsedTime: TimeInterval
    ) -> CachePolicyIndexState {
        let deadlineOrNil = self.deadlinesByIndex[index]

        guard let deadline = deadlineOrNil else {
            fatalError("Expected deadline, found nil")
        }

        if deadline >= elapsedTime {
            return .alive
        } else {
            return .expired
        }
    }

    private func deadlineFor(
        timeInterval: TimeInterval
    ) -> TimeInterval {
        let timeElapsed = self.timeIntervalSinceReferenceDate()

        assert(timeElapsed >= 0.0)
        
        let deadline = timeElapsed + timeInterval
        return deadline
    }

    private func timeIntervalFor(
        deadline: Metadata
    ) -> TimeInterval {
        let timeElapsed = self.timeIntervalSinceReferenceDate()

        assert(timeElapsed >= 0.0)

        let timeInterval = deadline - timeElapsed
        return timeInterval
    }

    private func timeIntervalSinceReferenceDate() -> TimeInterval {
        let date = self.dateProvider()
        return date.timeIntervalSince(self.referenceDate)
    }
}
