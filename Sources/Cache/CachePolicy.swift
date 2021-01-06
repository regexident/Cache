// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public protocol CachePolicy {
    /// The policy's index type.
    associatedtype Index: Hashable

    var isEmpty: Bool { get }
    var count: Int { get }

    /// Creates an empty policy.
    init()

    /// Creates an empty policy with preallocated space
    /// for at least the specified number of indices.
    ///
    /// - Note:
    ///   For performance reasons, the size of the newly allocated
    ///   storage might be greater than the requested capacity.
    ///   Use the policy's `capacity` property to determine the size
    ///   of the new storage.
    ///
    /// - Parameters:
    ///   - minimumCapacity:
    ///     The requested number of elements to store.
    init(minimumCapacity: Int)

    /// Inserts a new index into the policy.
    mutating func insert() -> Index

    /// Marks a index as used.
    mutating func use(_ index: Index)

    /// Removes a index chosen by the policy.
    mutating func remove() -> Index?

    /// Removed a index.
    mutating func remove(_ index: Index)

    /// Removes all indices from the policy.
    mutating func removeAll()

    /// Removes all indices from the policy.
    /// - Parameters:
    ///   - keepCapacity:
    ///     Pass `true` to keep the existing capacity of
    ///     the policy after removing its indices.
    mutating func removeAll(keepingCapacity keepCapacity: Bool)
}
