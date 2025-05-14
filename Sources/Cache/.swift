// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

extension CustomCache
where
    Cost == Int
{
    /// The default cost associated with all stored value,
    /// for which no individual cost was specified,
    /// unless overridden on initialization.
    public static var defaultCost: Cost {
        1
    }

    /// Creates an empty cache with preallocated space
    /// for at least the specified number of tokens
    /// with a `self.defaultCost` of `Self.defaultcost`.
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
    ///   - totalCostLimit:
    ///     The maximum total cost that the cache can
    ///     hold before it starts evicting objects.
    public init(
        minimumCapacity: Int? = nil,
        totalCostLimit: Cost? = nil
    ) {
        self.init(
            minimumCapacity: minimumCapacity,
            totalCostLimit: totalCostLimit,
            defaultCost: Self.defaultCost
        )
    }
}

extension CustomCache
where
    Cost == UInt
{
    /// The default cost associated with all stored value,
    /// for which no individual cost was specified,
    /// unless overridden on initialization.
    public static var defaultCost: Cost {
        1
    }

    /// Creates an empty cache with preallocated space
    /// for at least the specified number of tokens
    /// with a `self.defaultCost` of `Self.defaultcost`.
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
    ///   - totalCostLimit:
    ///     The maximum total cost that the cache can
    ///     hold before it starts evicting objects.
    public init(
        minimumCapacity: Int? = nil,
        totalCostLimit: Cost? = nil
    ) {
        self.init(
            minimumCapacity: minimumCapacity,
            totalCostLimit: totalCostLimit,
            defaultCost: Self.defaultCost
        )
    }
}

extension CustomCache
where
    Cost == Float
{
    /// The default cost associated with all stored value,
    /// for which no individual cost was specified,
    /// unless overridden on initialization.
    public static var defaultCost: Cost {
        1.0
    }

    /// Creates an empty cache with preallocated space
    /// for at least the specified number of tokens
    /// with a `self.defaultCost` of `Self.defaultcost`.
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
    ///   - totalCostLimit:
    ///     The maximum total cost that the cache can
    ///     hold before it starts evicting objects.
    public init(
        minimumCapacity: Int? = nil,
        totalCostLimit: Cost? = nil
    ) {
        self.init(
            minimumCapacity: minimumCapacity,
            totalCostLimit: totalCostLimit,
            defaultCost: Self.defaultCost
        )
    }
}

extension CustomCache
where
    Cost == Double
{
    /// The default cost associated with all stored value,
    /// for which no individual cost was specified,
    /// unless overridden on initialization.
    public static var defaultCost: Cost {
        1.0
    }

    /// Creates an empty cache with preallocated space
    /// for at least the specified number of tokens
    /// with a `self.defaultCost` of `Self.defaultcost`.
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
    ///   - totalCostLimit:
    ///     The maximum total cost that the cache can
    ///     hold before it starts evicting objects.
    public init(
        minimumCapacity: Int? = nil,
        totalCostLimit: Cost? = nil
    ) {
        self.init(
            minimumCapacity: minimumCapacity,
            totalCostLimit: totalCostLimit,
            defaultCost: Self.defaultCost
        )
    }
}
