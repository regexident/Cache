// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation

public protocol CachePolicy {
    /// The policy's token type.
    associatedtype Token: Hashable

    /// Creates an empty policy.
    init()

    /// Creates an empty policy with preallocated space
    /// for at least the specified number of tokens.
    init(minimumCapacity: Int)

    /// Inserts a new token into the policy.
    mutating func insert() -> Token

    /// Marks a token as used.
    mutating func use(_ token: Token)

    /// Returns the best token to be removed next
    mutating func next() -> Token?

    /// Removed a token.
    mutating func remove(_ token: Token)

    /// Removes all tokens from the policy.
    mutating func removeAll()

    /// Removes all tokens from the policy.
    /// - Parameter keepCapacity: Pass `true` to keep the existing capacity of the policy after removing its tokens.
    mutating func removeAll(keepingCapacity keepCapacity: Bool)
}
