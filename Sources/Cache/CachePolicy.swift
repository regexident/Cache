// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public protocol CachePayload {
    static var `default`: Self { get }
}

public struct NoPayload: CachePayload, Equatable {
    public static let `default`: Self = .init()
}

public enum CacheEvictionTrigger<Payload> {
    case alloc(payload: Payload)
    case trace
}

public protocol CachePolicy {
    /// The policy's index type.
    associatedtype Index: Hashable

    /// The policy's payload type.
    associatedtype Payload: CachePayload

    var isEmpty: Bool { get }
    var count: Int { get }

    /// Evict one or more indices from the policy.
    mutating func evictIfNeeded(
        for trigger: CacheEvictionTrigger<Payload>,
        callback: (Index) -> Void
    )

    /// Inserts a new index into the policy.
    mutating func insert(payload: Payload) -> Index

    /// Marks a index as used.
    mutating func use(_ index: Index)

    /// Removes a index chosen by the policy.
    mutating func remove() -> (index: Index, payload: Payload)?

    /// Removed a index.
    mutating func remove(_ index: Index) -> Payload

    /// Removes all indices from the policy.
    mutating func removeAll()

    /// Removes all indices from the policy.
    /// - Parameters:
    ///   - keepCapacity:
    ///     Pass `true` to keep the existing capacity of
    ///     the policy after removing its indices.
    mutating func removeAll(keepingCapacity keepCapacity: Bool)
}
