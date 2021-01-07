// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public protocol DefaultCacheMetadata {
    static var `default`: Self { get }
}

public struct NoMetadata: DefaultCacheMetadata, Equatable {
    public static let `default`: Self = .init()
}

public enum CachePolicyIndexState: Equatable {
    case alive
    case expired
}

public protocol CachePolicy {
    /// The policy's index type.
    associatedtype Index: Hashable

    /// The policy's metadata type.
    associatedtype Metadata

    /// A Boolean value indicating whether the policy is empty.
    var isEmpty: Bool { get }

    /// The number of indices in the policy.
    var count: Int { get }

    /// Returns `true` if the policy has enough capacity to
    /// add the provided additional `metadata` without exceeding
    /// its limits (if it has any), otherwise `false.`
    ///
    /// - Parameter metadata: The additional metadata to accomodate.
    func hasCapacity(forMetadata metadata: Metadata?) -> Bool

    /// Returns the lazy state of an index.
    ///
    /// - Note:
    ///   This method must only be called for indices that
    ///   are contained in the cache at the given time.
    ///
    /// - Parameter index: The index to inspect.
    func state(of index: Index) -> CachePolicyIndexState

    /// Inserts a new index into the policy.
    ///
    /// - Parameter metadata: The metadata to attach to the index
    mutating func insert(metadata: Metadata) -> Index

    /// Marks a index as used.
    ///
    /// - Note:
    ///   This method must only be called for indices that
    ///   are contained in the cache at the given time.
    ///
    /// - Parameters:
    ///   - index: The index to mark as used
    ///   - metadata: The metadata to attach to the index
    mutating func use(_ index: Index, metadata: Metadata) -> Index

    /// Removes an index chosen by the policy, if possible.
    mutating func remove() -> (index: Index, metadata: Metadata)?

    /// Removes a index.
    ///
    /// - Note:
    ///   This method must only be called for indices that
    ///   are contained in the cache at the given time.
    ///
    /// - Parameter index: The index to remove
    mutating func remove(_ index: Index) -> Metadata

    /// Removed expired indices, calling `callback` for each of them.
    ///
    /// - Parameter evictionCallback: The eviction callback.
    mutating func removeExpired(_ evictionCallback: (Index) -> Void)

    /// Removes all indices from the policy.
    mutating func removeAll()

    /// Removes all indices from the policy.
    ///
    /// - Parameter keepCapacity: Pass `true` to keep the existing capacity
    ///                           of the policy after removing its indices.
    mutating func removeAll(keepingCapacity keepCapacity: Bool)
}
