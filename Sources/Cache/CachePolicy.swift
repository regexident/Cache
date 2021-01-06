// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

public protocol DefaultCachePayload {
    static var `default`: Self { get }
}

public struct NoPayload: DefaultCachePayload, Equatable {
    public static let `default`: Self = .init()
}

public protocol CachePolicy {
    /// The policy's index type.
    associatedtype Index: Hashable

    /// The policy's payload type.
    associatedtype Payload

    var isEmpty: Bool { get }
    var count: Int { get }

    /// Returns `true` if the policy has enough capacity to
    /// add the provided additional `payload` without exceeding
    /// its limits (if it has any), otherwise `false.`
    ///
    /// - Parameter payload: The additional payload to accomodate.
    func hasCapacity(forPayload payload: Payload?) -> Bool

    /// Inserts a new index into the policy.
    mutating func insert(payload: Payload) -> Index

    /// Marks a index as used.
    mutating func use(
        _ index: Index,
        payload: Payload
    ) -> Index

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
    mutating func removeAll(
        keepingCapacity keepCapacity: Bool
    )
}
